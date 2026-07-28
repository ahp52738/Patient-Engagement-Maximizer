class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.string :preferred_language, null: false, default: "en"
      t.string :phone_number, null: false

      t.timestamps
    end
  end
end
