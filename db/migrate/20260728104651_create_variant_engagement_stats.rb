class CreateVariantEngagementStats < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_engagement_stats do |t|
      t.references :message_variant, null: false, foreign_key: true
      t.string :segment_key, null: false
      t.integer :sends_count, null: false, default: 0
      t.integer :responses_count, null: false, default: 0
      t.float :response_rate, null: false, default: 0.0
      t.float :avg_response_length
      t.integer :red_flag_count, null: false, default: 0
      t.datetime :calculated_at, null: false

      t.timestamps
    end
    add_index :variant_engagement_stats, [ :message_variant_id, :segment_key ], unique: true, name: "index_variant_stats_on_variant_and_segment"
  end
end
