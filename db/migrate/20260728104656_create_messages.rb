class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      # Only set for outbound check-in messages; inbound patient replies have no variant.
      t.references :message_variant, null: true, foreign_key: true
      # Set on an inbound message to link it to the outbound check-in it is replying to.
      t.references :responds_to_message, null: true, foreign_key: { to_table: :messages }
      t.string :direction, null: false
      t.text :body, null: false
      t.datetime :sent_at, null: false
      t.boolean :contains_red_flag, null: false, default: false

      t.timestamps
    end

    add_index :messages, :direction
  end
end
