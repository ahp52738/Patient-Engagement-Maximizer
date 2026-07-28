class CreateCurationReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :curation_reviews do |t|
      t.references :message_variant, null: false, foreign_key: true
      t.string :reviewer_name, null: false
      t.string :action, null: false
      t.text :notes
      t.datetime :reviewed_at, null: false

      t.timestamps
    end
  end
end
