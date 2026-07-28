class CreateMessageVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :message_variants do |t|
      t.references :checkin_template, null: false, foreign_key: true
      t.text :body, null: false
      t.string :status, null: false, default: "draft"
      t.string :created_by, null: false

      t.timestamps
    end
    add_index :message_variants, :status
  end
end
