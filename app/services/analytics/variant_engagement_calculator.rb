module Analytics
  # Recomputes VariantEngagementStat rows from raw send/response history.
  #
  # Stats are kept at three tiers of specificity per variant so the recommendation
  # engine can fall back gracefully for patients or variants with little history:
  #   1. "condition:<slug>|age_band:<band>" — most specific
  #   2. "condition:<slug>"                  — condition only
  #   3. "global"                            — every send of this variant, no segmentation
  #
  # Designed to run on a schedule (e.g. nightly) as new send/response data accumulates.
  class VariantEngagementCalculator
    def self.call
      new.call
    end

    def call
      MessageVariant.find_each { |variant| recalculate_for(variant) }
    end

    private

    def recalculate_for(variant)
      relevant_condition_ids = variant.checkin_template.condition_ids
      buckets = Hash.new { |hash, key| hash[key] = { sends: 0, responses: 0, response_length_sum: 0, red_flags: 0 } }

      sent_messages(variant).each do |sent_message|
        patient = sent_message.conversation.patient
        response = sent_message.response
        responded = response.present?

        segment_keys_for(patient, relevant_condition_ids).each do |key|
          bucket = buckets[key]
          bucket[:sends] += 1
          next unless responded

          bucket[:responses] += 1
          bucket[:response_length_sum] += response.response_length
          bucket[:red_flags] += 1 if response.contains_red_flag
        end
      end

      persist(variant, buckets)
    end

    def sent_messages(variant)
      variant.messages.outbound.includes(:response, conversation: { patient: :conditions })
    end

    def segment_keys_for(patient, relevant_condition_ids)
      keys = [ VariantEngagementStat::GLOBAL_SEGMENT ]

      patient.conditions.each do |condition|
        next unless relevant_condition_ids.include?(condition.id)

        keys << "condition:#{condition.slug}"
        keys << "condition:#{condition.slug}|age_band:#{patient.age_band}"
      end

      keys
    end

    def persist(variant, buckets)
      buckets.each do |segment_key, bucket|
        stat = variant.variant_engagement_stats.find_or_initialize_by(segment_key: segment_key)
        stat.sends_count = bucket[:sends]
        stat.responses_count = bucket[:responses]
        stat.response_rate = bucket[:sends].positive? ? bucket[:responses].to_f / bucket[:sends] : 0.0
        stat.avg_response_length = bucket[:responses].positive? ? bucket[:response_length_sum].to_f / bucket[:responses] : nil
        stat.red_flag_count = bucket[:red_flags]
        stat.calculated_at = Time.current
        stat.save!
      end
    end
  end
end
