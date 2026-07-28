class CreateCheckinTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :checkin_templates do |t|
      t.string :name, null: false
      t.string :category, null: false
      t.text :description

      t.timestamps
    end
    add_index :checkin_templates, :name, unique: true
    add_index :checkin_templates, :category
  end
end
