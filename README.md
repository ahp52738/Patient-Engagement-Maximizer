# Patient Engagement Maximizer

A Rails implementation of a continuous-improvement system for care-manager
check-in messages: it tracks which message variants get patients to respond,
segments that performance by patient condition and age, and recommends the
best-performing, curator-approved variant for each patient at send time.

Built for the Phamily SWE take-home exercise. This is the domain model and
service layer (analytics + recommendation engine), verified through specs and
seed data — there's intentionally no web UI or JSON API yet (see
[What's not built](#whats-not-built-yet)).

## The problem

Care managers send check-in texts (glucose, symptoms, medication, hydration,
etc.) to patients 1-2x/week. The goal is to maximize the number of patients
who respond in a given month, without trading that off against opt-out rate
or the platform's ability to catch a patient in real clinical distress.

Concretely, this means: the same "topic" of check-in should exist as multiple
curated variants (different wording/tone), the system should learn which
variant works best for which kind of patient, and it should keep proposing
enough of the untested variants that today's best answer isn't locked in
forever.

## How it works

**Domain model.** `Patient` → `Conversation` → `Message` (outbound check-ins
and inbound replies, linked via `responds_to_message`). Check-in copy is
organized as `CheckinTemplate` (a topic, e.g. "Glucose") → `MessageVariant`
(a specific wording of that topic). Variants move through a curation workflow
— `draft → pending_review → approved → active/archived` — logged in
`CurationReview`, so nothing reaches a patient without a human sign-off.

**Analytics.** `Analytics::VariantEngagementCalculator` walks the send/response
history and rolls it up into `VariantEngagementStat` rows at three tiers of
specificity per variant: `condition + age band`, `condition` alone, and
`global`. This is what lets recommendations get more personalized as more
data comes in, while still having something to fall back on when it doesn't.

**Recommendations.** `Recommendations::Engine` ranks active variants for a
given patient:
- excludes opted-out patients outright, and variants sent to this patient too
  recently (a cooldown, so nobody gets the same check-in on repeat)
- filters to variants relevant to the patient's conditions (or general
  templates like hydration, which apply to everyone) and, for seasonal
  templates, the current month
- scores by the most specific engagement-stat tier available, falling back
  from condition+age → condition → global → a cold-start baseline for brand
  new variants
- adds a small exploration bonus to lightly-tested variants (a simplified
  stand-in for a proper multi-armed bandit), so promising-but-unproven
  wording isn't starved of the data it needs to prove itself

**Clinical safety stays separate from engagement scoring.** Inbound replies
are scanned for red-flag keywords (chest pain, can't breathe, etc.) via
`Message#contains_red_flag`, independent of whatever the engagement model
thinks of that variant — a "good" response rate should never suppress a real
symptom report.

For the fuller reasoning behind these choices (metrics, failure modes,
curation workflow, how the system keeps improving over time), see the
write-up in the PR/commit description or ask — this README covers the
as-built system.

## Getting started

Requires Ruby 3.2.2 and Bundler. Uses SQLite, so there's nothing else to
install or configure.

```bash
bundle install
bin/rails db:create db:schema:load
bin/rails db:seed   # 20 patients, 10 weeks of simulated check-in history,
                     # computes engagement stats, prints sample recommendations
```

If the databases already exist from a previous run and `db:setup` complains
about a foreign key constraint on drop, reset cleanly instead:

```bash
bin/rails db:drop db:create db:schema:load
```

## Running the tests

```bash
bundle exec rspec       # 50 examples — models, curation workflow,
                         # Analytics::VariantEngagementCalculator, Recommendations::Engine
bundle exec rubocop     # style (Rails Omakase)
```

## Exploring it directly

There's no UI, so the console is the way to interact with the actual logic:

```bash
bin/rails console
```
```ruby
patient = Patient.joins(:conditions).first
Recommendations::Engine.new(patient).call.each do |r|
  puts "#{r.message_variant.checkin_template.name}: #{r.score} — #{r.rationale}"
end

# curation workflow
variant = MessageVariant.create!(checkin_template: CheckinTemplate.first,
  body: "Hi {first_name}, test?", created_by: "you")
variant.submit_for_review!
variant.approve!(reviewer: "you")
variant.activate!

# recompute stats after new send/response data comes in
Analytics::VariantEngagementCalculator.call
```

## Project structure

```
app/models/            Domain model: Patient, Condition, CheckinTemplate,
                        MessageVariant, Conversation, Message, OptOutEvent,
                        VariantEngagementStat, CurationReview
app/services/
  analytics/            Analytics::VariantEngagementCalculator
  recommendations/       Recommendations::Engine
db/seeds.rb             Realistic sample data + a live demo of the engine
spec/                   Model specs + service specs (RSpec, FactoryBot)
```

## What's not built yet

Scoped out to keep this focused on the domain model and decision logic:

- A curation UI for the content/clinical team to review and edit variants
  (currently done through the `MessageVariant` transition methods directly)
- JSON API endpoints (e.g. `GET /patients/:id/recommendations`) for a care
  manager–facing frontend to call
- A real ML model in place of the heuristic/statistical scorer — the
  `Recommendations::Engine` scoring logic is intentionally simple and
  well-isolated so it could be swapped for a trained model later without
  touching the rest of the system
- Formal A/B test bookkeeping (an `Experiment` model) — right now, "which
  variant did this patient get" is visible from `Message`/`MessageVariant`,
  but there's no explicit control-group assignment or significance testing
- A scheduled job to recompute `Analytics::VariantEngagementCalculator`
  automatically (it's called directly from seeds/console right now)
