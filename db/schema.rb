# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150115013857) do

  create_table "accounts", force: true do |t|
    t.string   "type",            limit: 64,                 null: false
    t.integer  "person_id",                                  null: false
    t.integer  "exporter_id"
    t.text     "name",                                       null: false
    t.string   "currency",        limit: 3,  default: "HUF", null: false
    t.integer  "type_code",                                  null: false
    t.integer  "subtype_code"
    t.integer  "closed",          limit: 1,  default: 0,     null: false
    t.boolean  "hidden",                     default: false, null: false
    t.text     "foreign_ids",                                null: false
    t.integer  "foreign_balance"
    t.datetime "updated_at",                                 null: false
    t.datetime "created_at",                                 null: false
  end

  create_table "business_shares", force: true do |t|
    t.integer "person_id",   null: false
    t.integer "business_id", null: false
    t.text    "share",       null: false
  end

  create_table "businesses", force: true do |t|
    t.integer  "treasury_id",            null: false
    t.string   "name",        limit: 64, null: false
    t.text     "comment",                null: false
    t.datetime "updated_at",             null: false
    t.datetime "created_at",             null: false
  end

  create_table "categories", force: true do |t|
    t.integer  "treasury_id",                    null: false
    t.integer  "business_id"
    t.integer  "applied_business_id"
    t.integer  "exporter_id"
    t.string   "name",                limit: 64, null: false
    t.datetime "updated_at",                     null: false
    t.datetime "created_at",                     null: false
    t.string   "ancestry"
  end

  add_index "categories", ["ancestry"], name: "ancestry", using: :btree

  create_table "categories_titles", force: true do |t|
    t.integer "title_id",            null: false
    t.integer "category_id",         null: false
    t.integer "applied_business_id"
  end

  add_index "categories_titles", ["title_id"], name: "maneuver_id", using: :btree

  create_table "exchange_rate_logs", force: true do |t|
    t.date     "date",                 null: false
    t.string   "currency",   limit: 3, null: false
    t.float    "rate",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exporters", force: true do |t|
    t.string   "type",        null: false
    t.integer  "treasury_id", null: false
    t.text     "cfg"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  create_table "operations", force: true do |t|
    t.integer  "title_id",             null: false
    t.integer  "type_code",  limit: 2
    t.integer  "account_id",           null: false
    t.integer  "amount",               null: false
    t.datetime "updated_at",           null: false
    t.datetime "created_at",           null: false
  end

  add_index "operations", ["title_id"], name: "maneuver_id", using: :btree

  create_table "parties", force: true do |t|
    t.integer "transaction_id", null: false
    t.integer "account_id",     null: false
    t.integer "amount",         null: false
    t.integer "payee_id"
  end

  create_table "people", force: true do |t|
    t.string   "type",        limit: 64,                 null: false
    t.integer  "treasury_id",                            null: false
    t.string   "name",        limit: 64,                 null: false
    t.integer  "type_code",                              null: false
    t.integer  "payee_id"
    t.integer  "user_id"
    t.boolean  "restricted",             default: false, null: false
    t.text     "foreign_ids",                            null: false
    t.datetime "updated_at",                             null: false
    t.datetime "created_at",                             null: false
  end

  create_table "shares", force: true do |t|
    t.integer "title_id",  null: false
    t.integer "person_id", null: false
    t.text    "share",     null: false
  end

  create_table "supervisings", force: true do |t|
    t.integer "user_id",     null: false
    t.integer "treasury_id", null: false
  end

  create_table "titles", force: true do |t|
    t.integer  "transaction_id"
    t.integer  "party_id",                       null: false
    t.date     "date"
    t.text     "comment",                        null: false
    t.integer  "amount",                         null: false
    t.integer  "applied_business_id"
    t.string   "type",                limit: 64, null: false
    t.datetime "updated_at",                     null: false
    t.datetime "created_at",                     null: false
  end

  create_table "transactions", force: true do |t|
    t.integer  "treasury_id",                 null: false
    t.integer  "foreign_id"
    t.integer  "importer_id"
    t.date     "date",                        null: false
    t.integer  "amount"
    t.text     "comment",                     null: false
    t.integer  "user_id"
    t.boolean  "supervised",  default: false, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "treasuries", force: true do |t|
    t.string "name", limit: 32, null: false
    t.string "type", limit: 32, null: false
  end

  create_table "users", force: true do |t|
    t.text     "email",                           null: false
    t.text     "password_digest",                 null: false
    t.boolean  "root",            default: false, null: false
    t.datetime "updated_at",                      null: false
    t.datetime "created_at",                      null: false
  end

end
