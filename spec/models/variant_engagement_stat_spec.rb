require "rails_helper"

RSpec.describe VariantEngagementStat, type: :model do
  it "prevents duplicate segment keys for the same variant" do
    variant = create(:message_variant)
    create(:variant_engagement_stat, message_variant: variant, segment_key: "global")

    duplicate = build(:variant_engagement_stat, message_variant: variant, segment_key: "global")
    expect(duplicate).not_to be_valid
  end

  it "rejects negative counts" do
    stat = build(:variant_engagement_stat, sends_count: -1)
    expect(stat).not_to be_valid
  end
end
