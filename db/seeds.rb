# Seeds a realistic slice of check-in history so the Analytics and
# Recommendations layers have something meaningful to work with.
#
# Run with: bin/rails db:seed

puts "Clearing existing data..."
[ CurationReview, VariantEngagementStat, Message, Conversation, OptOutEvent,
  MessageVariant, TemplateCondition, PatientCondition, CheckinTemplate, Condition, Patient ].each(&:delete_all)

srand(42)
Faker::Config.random = Random.new(42)

puts "Creating conditions..."
diabetes = Condition.create!(name: "Type 2 Diabetes")
hypertension = Condition.create!(name: "Hypertension")

puts "Creating check-in templates..."
glucose_template = CheckinTemplate.create!(name: "Glucose", category: "glucose",
  description: "Daily/weekly fasting blood sugar check-in")
glucose_template.conditions << diabetes

symptoms_template = CheckinTemplate.create!(name: "Diabetes Symptoms", category: "symptoms",
  description: "Screens for diabetes-related warning symptoms")
symptoms_template.conditions << diabetes

medication_template = CheckinTemplate.create!(name: "Medication", category: "medication",
  description: "Medication adherence, side effects, and refill check-in")
medication_template.conditions << diabetes
medication_template.conditions << hypertension

hydration_template = CheckinTemplate.create!(name: "Summer Hydration", category: "hydration",
  description: "Seasonal hydration reminder, relevant to all patients")
# Intentionally no condition link — general wellness, offered to everyone.

puts "Creating message variants..."

def build_variant(template, body, creator: "content_team")
  variant = template.message_variants.create!(body: body, status: "draft", created_by: creator)
  variant.submit_for_review!
  variant.approve!(reviewer: "clinical_review_bot")
  variant.activate!
  variant
end

glucose_a = build_variant(glucose_template,
  "Hi {first_name}, just checking in. What was your fasting blood sugar today?")
glucose_b = build_variant(glucose_template,
  "Hey {first_name}! Quick check-in — what was your blood sugar reading today?")
symptoms_a = build_variant(symptoms_template,
  "Hi {first_name}, how are you feeling today? Remember to let us know if you experience any of these " \
  "diabetes-related symptoms: increased thirst, frequent urination, extreme fatigue, blurry vision, " \
  "slow-healing sores, or unexplained weight loss.")
medication_a = build_variant(medication_template,
  "Hi {first_name}, just checking in on your medication. How is it working for you? Are you experiencing " \
  "any side effects or symptoms? Do you need any refills?")
hydration_a = build_variant(hydration_template,
  "Hi {first_name}, summer is here! Remember to drink plenty of water to prevent dehydration. " \
  "Aim for 8 glasses of water daily. How many glasses do you typically drink each day?")

puts "Creating patients..."
patients = Array.new(20) do
  patient = Patient.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    date_of_birth: Faker::Date.birthday(min_age: 28, max_age: 85),
    phone_number: "+1#{Faker::Number.number(digits: 10)}",
    preferred_language: "en"
  )
  condition = [ diabetes, diabetes, hypertension ].sample # skew toward diabetes to match our templates
  patient.conditions << condition
  patient.conditions << hypertension if condition == diabetes && rand < 0.3
  patient
end

opted_out_patient = patients.sample
OptOutEvent.create!(patient: opted_out_patient, opted_out_at: 3.days.ago, reason: "Replied STOP")
puts "  #{opted_out_patient.first_name} #{opted_out_patient.last_name} opted out and will get no recommendations."

# Baseline response rates per variant. glucose_b intentionally outperforms glucose_a
# so the seeded stats and the recommendation ranking below actually diverge from
# insertion order — that divergence is the point of the whole exercise.
base_response_rate = {
  glucose_a => 0.55,
  glucose_b => 0.70,
  symptoms_a => 0.50,
  medication_a => 0.60,
  hydration_a => 0.45
}

puts "Simulating 10 weeks of check-in history..."
patients.each do |patient|
  conversation = Conversation.create!(patient: patient, started_at: 10.weeks.ago)
  next if patient.opted_out?

  patient_conditions = patient.conditions.to_a
  eligible = []
  eligible += [ glucose_a, glucose_b, symptoms_a ] if patient_conditions.include?(diabetes)
  eligible << medication_a if (patient_conditions & [ diabetes, hypertension ]).any?
  eligible << hydration_a
  eligible.uniq!

  10.downto(1) do |weeks_ago|
    variant = eligible.sample
    sent_at = weeks_ago.weeks.ago + rand(0..4).days

    outbound = conversation.messages.create!(
      message_variant: variant, direction: "outbound",
      body: variant.render_for(patient), sent_at: sent_at
    )

    probability = base_response_rate.fetch(variant)
    probability += 0.15 if variant == glucose_a && patient.age_band == "60_plus"
    probability += 0.10 if variant == glucose_b && patient.age_band == "under_40"
    probability = probability.clamp(0.05, 0.95)
    next unless rand < probability

    response_body = if rand < 0.05
      "I've been having chest pain since yesterday, is that normal?"
    else
      Faker::Lorem.sentence(word_count: rand(3..15))
    end

    conversation.messages.create!(
      direction: "inbound", body: response_body,
      sent_at: sent_at + rand(1..600).minutes, responds_to_message: outbound
    )
  end
end

puts "Calculating engagement stats..."
Analytics::VariantEngagementCalculator.call

puts "\n--- Sample recommendations ---"
(patients.first(3) + [ opted_out_patient ]).uniq.each do |patient|
  conditions_label = patient.conditions.pluck(:name).join(", ")
  puts "\n#{patient.first_name} #{patient.last_name} (age #{patient.age}, #{patient.age_band}, #{conditions_label})"

  recommendations = Recommendations::Engine.new(patient).call
  if recommendations.empty?
    puts "  -> no recommendations (opted out, or no eligible templates)"
  else
    recommendations.each_with_index do |recommendation, index|
      variant = recommendation.message_variant
      puts "  #{index + 1}. [#{variant.checkin_template.name}] score=#{recommendation.score} — #{recommendation.rationale}"
      puts "     \"#{variant.render_for(patient)}\""
    end
  end
end

puts "\nSeeded #{Patient.count} patients, #{Message.count} messages, #{VariantEngagementStat.count} engagement stats."
