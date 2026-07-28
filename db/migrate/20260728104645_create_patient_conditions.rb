class CreatePatientConditions < ActiveRecord::Migration[8.1]
  def change
    create_table :patient_conditions do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :condition, null: false, foreign_key: true
      t.date :diagnosed_at

      t.timestamps
    end
    add_index :patient_conditions, [ :patient_id, :condition_id ], unique: true
  end
end
