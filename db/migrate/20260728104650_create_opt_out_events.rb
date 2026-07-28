class CreateOptOutEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :opt_out_events do |t|
      t.references :patient, null: false, foreign_key: true
      t.datetime :opted_out_at, null: false
      t.string :reason

      t.timestamps
    end
  end
end
