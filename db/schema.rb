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

ActiveRecord::Schema[7.1].define(version: 2026_11_10_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "demo", default: false, null: false
    t.jsonb "qualification_criteria", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "field_sets", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.jsonb "fields", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_field_sets_on_company_id_and_name", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "lead_qualifications", force: :cascade do |t|
    t.bigint "lead_id", null: false
    t.string "status", default: "pending", null: false
    t.decimal "score", precision: 4, scale: 3
    t.string "confidence"
    t.string "model_version"
    t.jsonb "answers_snapshot", default: {}, null: false
    t.jsonb "criteria_snapshot", default: {}, null: false
    t.string "error_message"
    t.string "outcome"
    t.datetime "evaluated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_lead_qualifications_on_lead_id", unique: true
  end

  create_table "leads", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.jsonb "form_fields", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_leads_on_company_id"
  end

  add_foreign_key "field_sets", "companies"
  add_foreign_key "lead_qualifications", "leads"
  add_foreign_key "leads", "companies"
end
