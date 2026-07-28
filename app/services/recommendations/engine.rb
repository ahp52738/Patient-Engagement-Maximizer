module Recommendations
  # Ranks active, curated message variants for a single patient at the moment a
  # care manager is composing a check-in.
  #
  # Scoring falls back through progressively less specific engagement data
  # (condition + age band -> condition -> global -> cold start) so that new
  # patients and new variants still get a reasonable recommendation instead of
  # an empty list. A small exploration bonus is added for lightly-tested
  # variants, a simplified stand-in for a proper multi-armed bandit — it keeps
  # promising-but-unproven variants from being starved of the data they'd need
  # to ever prove themselves.
  class Engine
    Recommendation = Struct.new(:message_variant, :score, :rationale, keyword_init: true)

    DEFAULT_LIMIT = 3
    RECENT_SEND_COOLDOWN = 3.days
    MIN_SAMPLE_SIZE_FOR_CONFIDENCE = 20
    EXPLORATION_BONUS = 0.05
    COLD_START_SCORE = 0.3 # assumed baseline SMS response rate absent any data

    def initialize(patient, limit: DEFAULT_LIMIT, as_of: Date.current)
      @patient = patient
      @limit = limit
      @as_of = as_of
    end

    def call
      return [] if patient.opted_out?

      candidate_variants
        .map { |variant| score_variant(variant) }
        .sort_by { |recommendation| -recommendation.score }
        .first(limit)
    end

    private

    attr_reader :patient, :limit, :as_of

    def candidate_variants
      MessageVariant.recommendable
        .includes(:checkin_template, :variant_engagement_stats)
        .select { |variant| relevant_to_patient?(variant) }
        .reject { |variant| sent_too_recently?(variant) }
    end

    def relevant_to_patient?(variant)
      template = variant.checkin_template
      return false unless template.seasonally_relevant?(date: as_of)
      return true unless template.condition_specific?

      (template.condition_ids & patient.condition_ids).any?
    end

    def sent_too_recently?(variant)
      variant.messages.outbound
        .joins(:conversation)
        .where(conversations: { patient_id: patient.id })
        .where("messages.sent_at > ?", as_of.to_time - RECENT_SEND_COOLDOWN)
        .exists?
    end

    def score_variant(variant)
      stat, tier = stat_for(variant)
      sample_size = stat&.sends_count.to_i
      score = stat&.response_rate || COLD_START_SCORE
      exploring = sample_size < MIN_SAMPLE_SIZE_FOR_CONFIDENCE
      score += EXPLORATION_BONUS if exploring

      Recommendation.new(
        message_variant: variant,
        score: score.round(4),
        rationale: rationale_for(tier, stat, exploring)
      )
    end

    # Tries condition+age_band, then condition-only, then the variant's global
    # stat, in order of specificity — returns the first tier with real send history.
    def stat_for(variant)
      relevant_conditions = variant.checkin_template.conditions.select { |c| patient.condition_ids.include?(c.id) }
      stats_by_key = variant.variant_engagement_stats.index_by(&:segment_key)

      tier1_keys = relevant_conditions.map { |c| "condition:#{c.slug}|age_band:#{patient.age_band}" }
      tier1 = best_stat(stats_by_key, tier1_keys)
      return [ tier1, :condition_and_age ] if tier1

      tier2_keys = relevant_conditions.map { |c| "condition:#{c.slug}" }
      tier2 = best_stat(stats_by_key, tier2_keys)
      return [ tier2, :condition ] if tier2

      global = stats_by_key[VariantEngagementStat::GLOBAL_SEGMENT]
      return [ global, :global ] if global&.sends_count.to_i.positive?

      [ nil, :cold_start ]
    end

    def best_stat(stats_by_key, keys)
      keys.filter_map { |key| stats_by_key[key] }.select { |stat| stat.sends_count.positive? }.max_by(&:sends_count)
    end

    def rationale_for(tier, stat, exploring)
      base =
        case tier
        when :condition_and_age
          "#{percent(stat.response_rate)} response rate among patients with a similar condition and age (n=#{stat.sends_count})"
        when :condition
          "#{percent(stat.response_rate)} response rate among patients with the same condition (n=#{stat.sends_count})"
        when :global
          "#{percent(stat.response_rate)} response rate across all patients sent this message (n=#{stat.sends_count})"
        else
          "No send history yet for this message — using a baseline estimate"
        end

      exploring ? "#{base}; prioritized to gather more data" : base
    end

    def percent(rate)
      "#{(rate * 100).round}%"
    end
  end
end
