# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_28_104656) do
  create_table "checkin_templates", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_checkin_templates_on_category"
    t.index ["name"], name: "index_checkin_templates_on_name", unique: true
  end

  create_table "conditions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_conditions_on_name", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "patient_id", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_conversations_on_patient_id"
  end

  create_table "curation_reviews", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.integer "message_variant_id", null: false
    t.text "notes"
    t.datetime "reviewed_at", null: false
    t.string "reviewer_name", null: false
    t.datetime "updated_at", null: false
    t.index ["message_variant_id"], name: "index_curation_reviews_on_message_variant_id"
  end

  create_table "message_variants", force: :cascade do |t|
    t.text "body", null: false
    t.integer "checkin_template_id", null: false
    t.datetime "created_at", null: false
    t.string "created_by", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["checkin_template_id"], name: "index_message_variants_on_checkin_template_id"
    t.index ["status"], name: "index_message_variants_on_status"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.boolean "contains_red_flag", default: false, null: false
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.integer "message_variant_id"
    t.integer "responds_to_message_id"
    t.datetime "sent_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["direction"], name: "index_messages_on_direction"
    t.index ["message_variant_id"], name: "index_messages_on_message_variant_id"
    t.index ["responds_to_message_id"], name: "index_messages_on_responds_to_message_id"
  end

  create_table "opt_out_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "opted_out_at", null: false
    t.integer "patient_id", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_opt_out_events_on_patient_id"
  end

  create_table "patient_conditions", force: :cascade do |t|
    t.integer "condition_id", null: false
    t.datetime "created_at", null: false
    t.date "diagnosed_at"
    t.integer "patient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["condition_id"], name: "index_patient_conditions_on_condition_id"
    t.index ["patient_id", "condition_id"], name: "index_patient_conditions_on_patient_id_and_condition_id", unique: true
    t.index ["patient_id"], name: "index_patient_conditions_on_patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone_number", null: false
    t.string "preferred_language", default: "en", null: false
    t.datetime "updated_at", null: false
  end

  create_table "template_conditions", force: :cascade do |t|
    t.integer "checkin_template_id", null: false
    t.integer "condition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checkin_template_id", "condition_id"], name: "index_template_conditions_on_template_and_condition", unique: true
    t.index ["checkin_template_id"], name: "index_template_conditions_on_checkin_template_id"
    t.index ["condition_id"], name: "index_template_conditions_on_condition_id"
  end

  create_table "variant_engagement_stats", force: :cascade do |t|
    t.float "avg_response_length"
    t.datetime "calculated_at", null: false
    t.datetime "created_at", null: false
    t.integer "message_variant_id", null: false
    t.integer "red_flag_count", default: 0, null: false
    t.float "response_rate", default: 0.0, null: false
    t.integer "responses_count", default: 0, null: false
    t.string "segment_key", null: false
    t.integer "sends_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_variant_id", "segment_key"], name: "index_variant_stats_on_variant_and_segment", unique: true
    t.index ["message_variant_id"], name: "index_variant_engagement_stats_on_message_variant_id"
  end

  add_foreign_key "conversations", "patients"
  add_foreign_key "curation_reviews", "message_variants"
  add_foreign_key "message_variants", "checkin_templates"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "message_variants"
  add_foreign_key "messages", "messages", column: "responds_to_message_id"
  add_foreign_key "opt_out_events", "patients"
  add_foreign_key "patient_conditions", "conditions"
  add_foreign_key "patient_conditions", "patients"
  add_foreign_key "template_conditions", "checkin_templates"
  add_foreign_key "template_conditions", "conditions"
  add_foreign_key "variant_engagement_stats", "message_variants"
end
