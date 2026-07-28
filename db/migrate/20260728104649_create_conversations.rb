class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :patient, null: false, foreign_key: true
      t.datetime :started_at, null: false

      t.timestamps
    end
  end
end
