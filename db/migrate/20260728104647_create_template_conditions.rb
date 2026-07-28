class CreateTemplateConditions < ActiveRecord::Migration[8.1]
  def change
    create_table :template_conditions do |t|
      t.references :checkin_template, null: false, foreign_key: true
      t.references :condition, null: false, foreign_key: true

      t.timestamps
    end
    add_index :template_conditions, [ :checkin_template_id, :condition_id ], unique: true, name: "index_template_conditions_on_template_and_condition"
  end
end
