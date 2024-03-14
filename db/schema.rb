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

ActiveRecord::Schema.define(version: 2024_03_14_133536) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "batch_process_logs", force: :cascade do |t|
    t.string "filename"
    t.string "file_size"
    t.date "processed_date"
    t.integer "rows"
    t.integer "columns"
    t.string "image_properties"
    t.boolean "database_match", default: false, null: false
    t.boolean "folder_match", default: false, null: false
    t.boolean "error", default: false, null: false
    t.string "message"
    t.bigint "batch_process_id"
    t.bigint "tile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["batch_process_id"], name: "index_batch_process_logs_on_batch_process_id"
    t.index ["tile_id"], name: "index_batch_process_logs_on_tile_id"
  end

  create_table "batch_processes", force: :cascade do |t|
    t.datetime "validate_datetime"
    t.datetime "start_datetime"
    t.datetime "end_datetime"
    t.integer "number_of_tiffs"
    t.string "input_directory"
    t.string "content_file"
    t.boolean "error", default: false, null: false
    t.string "message"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_batch_processes_on_creator_id"
  end

  create_table "cameras", force: :cascade do |t|
    t.string "name", null: false
    t.string "manufacturer"
    t.string "model"
    t.string "serial_number"
    t.date "manufactured_date"
    t.boolean "sl", default: true, null: false
    t.boolean "nri", default: true, null: false
    t.boolean "naip", default: true, null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_cameras_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "alias"
    t.boolean "sl", default: true, null: false
    t.boolean "nri", default: true, null: false
    t.boolean "naip", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contract_awards", force: :cascade do |t|
    t.string "project"
    t.string "project_no"
    t.decimal "amount", precision: 9, scale: 2
    t.decimal "flight_amount", precision: 9, scale: 2
    t.decimal "production_amount", precision: 9, scale: 2
    t.date "start_date"
    t.date "end_date"
    t.bigint "state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project"], name: "index_contract_awards_on_project"
    t.index ["project_no"], name: "index_contract_awards_on_project_no"
    t.index ["state_id"], name: "index_contract_awards_on_state_id"
  end

  create_table "contract_rates", force: :cascade do |t|
    t.string "project"
    t.string "project_no"
    t.string "company_alias"
    t.string "phase"
    t.date "start_date"
    t.date "end_date"
    t.bigint "state_id"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "cost", precision: 10, scale: 9
    t.decimal "sub_cost", precision: 10, scale: 9, default: "0.0"
    t.index ["company_alias"], name: "index_contract_rates_on_company_alias"
    t.index ["company_id"], name: "index_contract_rates_on_company_id"
    t.index ["project"], name: "index_contract_rates_on_project"
    t.index ["project_no"], name: "index_contract_rates_on_project_no"
    t.index ["state_id"], name: "index_contract_rates_on_state_id"
  end

  create_table "counties", force: :cascade do |t|
    t.string "fips"
    t.string "full_fips"
    t.string "name"
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.bigint "state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fips"], name: "index_counties_on_fips"
    t.index ["full_fips"], name: "index_counties_on_full_fips"
    t.index ["name"], name: "index_counties_on_name"
    t.index ["state_id"], name: "index_counties_on_state_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "dissolved_footprints", force: :cascade do |t|
    t.string "name", null: false
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["geom"], name: "index_dissolved_footprints_on_geom", using: :gist
  end

  create_table "doqq_footprints", force: :cascade do |t|
    t.bigint "doqq_id"
    t.bigint "footprint_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doqq_id"], name: "index_doqq_footprints_on_doqq_id"
    t.index ["footprint_id"], name: "index_doqq_footprints_on_footprint_id"
  end

  create_table "doqqs", force: :cascade do |t|
    t.string "filename"
    t.string "project_state_name", null: false
    t.string "project_no"
    t.string "apfo_name"
    t.string "qq_apfo_name"
    t.string "quadrant"
    t.string "quad_state_abvs"
    t.string "film_type"
    t.string "q_lat"
    t.string "q_lon"
    t.string "loc"
    t.string "gsd"
    t.string "q_key", null: false
    t.string "qq_name"
    t.decimal "acres"
    t.decimal "sq_miles"
    t.integer "rows"
    t.integer "columns"
    t.string "psn"
    t.date "flight_date"
    t.datetime "median_flight_date_time"
    t.date "ortho_proc_date"
    t.date "dump_date"
    t.date "ship_date"
    t.date "at_start_date"
    t.date "at_done_date"
    t.date "asi_rejected_date"
    t.date "usda_accepted_date"
    t.date "usda_rejected_date"
    t.date "production_upload_date"
    t.date "invoiced_date"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.string "flown_by_name"
    t.string "pilot"
    t.string "sensor_operator"
    t.string "plane_name"
    t.string "camera_name"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.text "notes"
    t.text "review_desc"
    t.string "counties"
    t.bigint "camera_id"
    t.bigint "plane_id"
    t.bigint "packing_slip_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "project_state_id"
    t.bigint "utm_id"
    t.bigint "flown_by_id"
    t.bigint "upload_id"
    t.bigint "vector_metadatum_id"
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acres"], name: "index_doqqs_on_acres"
    t.index ["apfo_name"], name: "index_doqqs_on_apfo_name"
    t.index ["asi_rejected_date"], name: "index_doqqs_on_asi_rejected_date"
    t.index ["at_done_date"], name: "index_doqqs_on_at_done_date"
    t.index ["at_start_date"], name: "index_doqqs_on_at_start_date"
    t.index ["camera_id"], name: "index_doqqs_on_camera_id"
    t.index ["counties"], name: "index_doqqs_on_counties"
    t.index ["county_id"], name: "index_doqqs_on_county_id"
    t.index ["dump_date"], name: "index_doqqs_on_dump_date"
    t.index ["filename"], name: "index_doqqs_on_filename"
    t.index ["flight_date"], name: "index_doqqs_on_flight_date"
    t.index ["flown_by_id"], name: "index_doqqs_on_flown_by_id"
    t.index ["geom"], name: "index_doqqs_on_geom", using: :gist
    t.index ["invoiced_date"], name: "index_doqqs_on_invoiced_date"
    t.index ["median_flight_date_time"], name: "index_doqqs_on_median_flight_date_time"
    t.index ["ortho_proc_date"], name: "index_doqqs_on_ortho_proc_date"
    t.index ["packing_slip_id"], name: "index_doqqs_on_packing_slip_id"
    t.index ["plane_id"], name: "index_doqqs_on_plane_id"
    t.index ["production_upload_date"], name: "index_doqqs_on_production_upload_date"
    t.index ["project_no"], name: "index_doqqs_on_project_no"
    t.index ["project_state_id"], name: "index_doqqs_on_project_state_id"
    t.index ["project_state_name"], name: "index_doqqs_on_project_state_name"
    t.index ["q_key"], name: "index_doqqs_on_q_key"
    t.index ["qq_apfo_name"], name: "index_doqqs_on_qq_apfo_name"
    t.index ["qq_name"], name: "index_doqqs_on_qq_name"
    t.index ["quadrant"], name: "index_doqqs_on_quadrant"
    t.index ["ship_date"], name: "index_doqqs_on_ship_date"
    t.index ["sq_miles"], name: "index_doqqs_on_sq_miles"
    t.index ["state_id"], name: "index_doqqs_on_state_id"
    t.index ["upload_id"], name: "index_doqqs_on_upload_id"
    t.index ["usda_accepted_date"], name: "index_doqqs_on_usda_accepted_date"
    t.index ["usda_rejected_date"], name: "index_doqqs_on_usda_rejected_date"
    t.index ["utm_id"], name: "index_doqqs_on_utm_id"
    t.index ["vector_metadatum_id"], name: "index_doqqs_on_vector_metadatum_id"
  end

  create_table "easements", force: :cascade do |t|
    t.string "poly_id", null: false
    t.string "original_poly_id", null: false
    t.string "project", null: false
    t.string "project_no"
    t.string "project_state_name", null: false
    t.string "phase"
    t.boolean "multiple_geom", default: false, null: false
    t.date "flight_date"
    t.string "scale"
    t.decimal "acres"
    t.decimal "buffer_acres"
    t.string "asi_block"
    t.string "status"
    t.string "usda_region"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "original_fid"
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.bigint "upload_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "project_state_id"
    t.bigint "utm_id"
    t.bigint "time_zone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contract_award_id"
    t.string "priority"
    t.index ["acres"], name: "index_easements_on_acres"
    t.index ["contract_award_id"], name: "index_easements_on_contract_award_id"
    t.index ["county_id"], name: "index_easements_on_county_id"
    t.index ["flight_date"], name: "index_easements_on_flight_date"
    t.index ["geom"], name: "index_easements_on_geom", using: :gist
    t.index ["original_poly_id"], name: "index_easements_on_original_poly_id"
    t.index ["poly_id"], name: "index_easements_on_poly_id"
    t.index ["project"], name: "index_easements_on_project"
    t.index ["project_no"], name: "index_easements_on_project_no"
    t.index ["project_state_id"], name: "index_easements_on_project_state_id"
    t.index ["project_state_name"], name: "index_easements_on_project_state_name"
    t.index ["state_id"], name: "index_easements_on_state_id"
    t.index ["time_zone_id"], name: "index_easements_on_time_zone_id"
    t.index ["upload_id"], name: "index_easements_on_upload_id"
    t.index ["utm_id"], name: "index_easements_on_utm_id"
  end

  create_table "flight_times", force: :cascade do |t|
    t.date "flight_date"
    t.datetime "start_date"
    t.datetime "end_date"
    t.bigint "tile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_date"], name: "index_flight_times_on_flight_date"
    t.index ["tile_id"], name: "index_flight_times_on_tile_id"
  end

  create_table "footprints", force: :cascade do |t|
    t.string "project"
    t.string "project_state_name"
    t.date "flight_date"
    t.datetime "flight_date_time"
    t.string "original_strip_frame"
    t.string "strip_frame"
    t.string "flown_by_alias"
    t.string "flown_by_name"
    t.string "pilot_name"
    t.string "camera_operator_name"
    t.string "plane_name"
    t.string "camera_name"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.boolean "nri", default: false, null: false
    t.boolean "sl", default: false, null: false
    t.boolean "naip", default: false, null: false
    t.boolean "associated", default: false, null: false
    t.decimal "centroid_latitude", precision: 11, scale: 8
    t.decimal "centroid_longitude", precision: 11, scale: 8
    t.text "notes"
    t.text "review_desc"
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.bigint "upload_id"
    t.bigint "camera_id"
    t.bigint "plane_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "utm_id"
    t.bigint "project_state_id"
    t.bigint "vector_metadatum_id"
    t.bigint "flown_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["camera_id"], name: "index_footprints_on_camera_id"
    t.index ["county_id"], name: "index_footprints_on_county_id"
    t.index ["flown_by_id"], name: "index_footprints_on_flown_by_id"
    t.index ["geom"], name: "index_footprints_on_geom", using: :gist
    t.index ["plane_id"], name: "index_footprints_on_plane_id"
    t.index ["project"], name: "index_footprints_on_project"
    t.index ["project_state_id"], name: "index_footprints_on_project_state_id"
    t.index ["project_state_name"], name: "index_footprints_on_project_state_name"
    t.index ["state_id"], name: "index_footprints_on_state_id"
    t.index ["strip_frame", "flight_date", "camera_id", "flown_by_id", "project", "project_state_id"], name: "unique_strip_frame", unique: true
    t.index ["upload_id"], name: "index_footprints_on_upload_id"
    t.index ["utm_id"], name: "index_footprints_on_utm_id"
    t.index ["vector_metadatum_id"], name: "index_footprints_on_vector_metadatum_id"
  end

  create_table "frame_centers", force: :cascade do |t|
    t.string "project"
    t.string "strip"
    t.string "strip_frame"
    t.string "project_state_name"
    t.decimal "gpstime", precision: 11, scale: 5
    t.decimal "x", precision: 11, scale: 3
    t.decimal "y", precision: 11, scale: 3
    t.decimal "z", precision: 10, scale: 3
    t.decimal "omega", precision: 10, scale: 5
    t.decimal "phi", precision: 10, scale: 5
    t.decimal "kappa", precision: 10, scale: 5
    t.datetime "flight_date"
    t.decimal "sun_angle", precision: 10, scale: 3
    t.boolean "sun_angle_error", default: false, null: false
    t.text "notes"
    t.text "review_desc"
    t.string "flown_by_name"
    t.string "flown_by_alias"
    t.string "camera_name"
    t.string "plane_name"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.boolean "nri", default: false, null: false
    t.boolean "sl", default: false, null: false
    t.boolean "naip", default: false, null: false
    t.decimal "latitude", precision: 11, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.boolean "build_geom", default: false, null: false
    t.geography "geom", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.bigint "footprint_id"
    t.bigint "upload_id"
    t.bigint "flown_by_id"
    t.bigint "camera_id"
    t.bigint "plane_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "project_state_id"
    t.bigint "utm_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["camera_id"], name: "index_frame_centers_on_camera_id"
    t.index ["county_id"], name: "index_frame_centers_on_county_id"
    t.index ["flown_by_id"], name: "index_frame_centers_on_flown_by_id"
    t.index ["footprint_id"], name: "index_frame_centers_on_footprint_id"
    t.index ["geom"], name: "index_frame_centers_on_geom", using: :gist
    t.index ["plane_id"], name: "index_frame_centers_on_plane_id"
    t.index ["project"], name: "index_frame_centers_on_project"
    t.index ["project_state_id"], name: "index_frame_centers_on_project_state_id"
    t.index ["project_state_name"], name: "index_frame_centers_on_project_state_name"
    t.index ["state_id"], name: "index_frame_centers_on_state_id"
    t.index ["strip"], name: "index_frame_centers_on_strip"
    t.index ["strip_frame"], name: "index_frame_centers_on_strip_frame"
    t.index ["upload_id"], name: "index_frame_centers_on_upload_id"
    t.index ["utm_id"], name: "index_frame_centers_on_utm_id"
  end

  create_table "historic_assocs", force: :cascade do |t|
    t.text "search_terms"
    t.string "historicable_type"
    t.bigint "historicable_id"
    t.bigint "history_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["historicable_type", "historicable_id"], name: "index_historic_assocs_on_historicable_type_and_historicable_id"
    t.index ["history_id"], name: "index_historic_assocs_on_history_id"
    t.index ["search_terms"], name: "index_historic_assocs_on_search_terms"
  end

  create_table "histories", force: :cascade do |t|
    t.string "message"
    t.string "url"
    t.string "file_path"
    t.string "action_type"
    t.text "search_terms"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type"], name: "index_histories_on_action_type"
    t.index ["creator_id"], name: "index_histories_on_creator_id"
    t.index ["message"], name: "index_histories_on_message"
    t.index ["search_terms"], name: "index_histories_on_search_terms"
  end

  create_table "imagery_paths", force: :cascade do |t|
    t.string "project"
    t.text "path"
    t.string "pathable_type"
    t.bigint "pathable_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pathable_type", "pathable_id"], name: "index_imagery_paths_on_pathable_type_and_pathable_id"
    t.index ["project"], name: "index_imagery_paths_on_project"
    t.index ["user_id"], name: "index_imagery_paths_on_user_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "process_type"
    t.string "filename"
    t.string "message"
    t.text "error_message"
    t.boolean "active", default: true, null: false
    t.boolean "success", default: false, null: false
    t.integer "delayed_job_id"
    t.bigint "upload_id"
    t.bigint "creator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_jobs_on_creator_id"
    t.index ["finished_at"], name: "index_jobs_on_finished_at"
    t.index ["process_type"], name: "index_jobs_on_process_type"
    t.index ["started_at"], name: "index_jobs_on_started_at"
    t.index ["upload_id"], name: "index_jobs_on_upload_id"
  end

  create_table "mail_group_users", force: :cascade do |t|
    t.bigint "mail_group_id"
    t.bigint "user_id"
    t.index ["mail_group_id"], name: "index_mail_group_users_on_mail_group_id"
    t.index ["user_id"], name: "index_mail_group_users_on_user_id"
  end

  create_table "mail_groups", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_mail_groups_on_name"
  end

  create_table "mailboxes", force: :cascade do |t|
    t.string "subject"
    t.text "message"
    t.datetime "sent_at"
    t.datetime "opened_at"
    t.string "token"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "route"
    t.integer "retry_count", default: 0
    t.index ["token"], name: "index_mailboxes_on_token"
    t.index ["user_id"], name: "index_mailboxes_on_user_id"
  end

  create_table "packing_slips", force: :cascade do |t|
    t.string "name"
    t.string "project"
    t.date "shipped_date"
    t.date "approved_date"
    t.date "invoiced_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_date"], name: "index_packing_slips_on_approved_date"
    t.index ["invoiced_date"], name: "index_packing_slips_on_invoiced_date"
    t.index ["name", "project"], name: "index_packing_slips_on_name_and_project", unique: true
    t.index ["shipped_date"], name: "index_packing_slips_on_shipped_date"
  end

  create_table "photo_indices", force: :cascade do |t|
    t.string "project"
    t.string "strip"
    t.string "frame"
    t.string "strip_frame"
    t.string "flown_by_name"
    t.string "camera_name"
    t.string "county_name"
    t.string "state_name"
    t.string "utm_zone"
    t.boolean "nri", default: false, null: false
    t.boolean "sl", default: false, null: false
    t.boolean "naip", default: false, null: false
    t.date "flight_date"
    t.datetime "flight_date_time"
    t.decimal "gpstime"
    t.decimal "sun_angle", precision: 10, scale: 3
    t.boolean "sun_angle_error", default: false, null: false
    t.decimal "recorded_sun_angle", precision: 10, scale: 3
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "notes"
    t.geography "geom", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.bigint "footprint_id"
    t.bigint "rejected_footprint_id"
    t.bigint "upload_id"
    t.bigint "flown_by_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "utm_id"
    t.bigint "camera_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["camera_id"], name: "index_photo_indices_on_camera_id"
    t.index ["county_id"], name: "index_photo_indices_on_county_id"
    t.index ["flown_by_id"], name: "index_photo_indices_on_flown_by_id"
    t.index ["footprint_id"], name: "index_photo_indices_on_footprint_id"
    t.index ["geom"], name: "index_photo_indices_on_geom", using: :gist
    t.index ["notes"], name: "index_photo_indices_on_notes"
    t.index ["rejected_footprint_id"], name: "index_photo_indices_on_rejected_footprint_id"
    t.index ["state_id"], name: "index_photo_indices_on_state_id"
    t.index ["strip_frame"], name: "index_photo_indices_on_strip_frame"
    t.index ["sun_angle"], name: "index_photo_indices_on_sun_angle"
    t.index ["upload_id"], name: "index_photo_indices_on_upload_id"
    t.index ["utm_id"], name: "index_photo_indices_on_utm_id"
  end

  create_table "planes", force: :cascade do |t|
    t.string "name", null: false
    t.string "model"
    t.boolean "sl", default: true, null: false
    t.boolean "nri", default: true, null: false
    t.boolean "naip", default: true, null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_planes_on_company_id"
  end

  create_table "rejected_airborne_digital_sensors", force: :cascade do |t|
    t.date "rejected_date"
    t.string "rejection_type"
    t.bigint "original_id"
    t.string "LINEID"
    t.date "at_start_date"
    t.date "at_done_date"
    t.boolean "covered", default: false, null: false
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.bigint "upload_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["geom"], name: "index_rejected_airborne_digital_sensors_on_geom", using: :gist
    t.index ["rejected_date"], name: "index_rejected_airborne_digital_sensors_on_rejected_date"
    t.index ["rejection_type"], name: "index_rejected_airborne_digital_sensors_on_rejection_type"
    t.index ["upload_id"], name: "index_rejected_airborne_digital_sensors_on_upload_id"
  end

  create_table "rejected_footprints", force: :cascade do |t|
    t.date "rejected_date"
    t.string "rejection_type"
    t.bigint "original_id"
    t.string "project"
    t.string "project_state_name"
    t.date "flight_date"
    t.datetime "flight_date_time"
    t.string "original_strip_frame"
    t.string "strip_frame"
    t.string "flown_by_name"
    t.string "flown_by_alias"
    t.string "pilot_name"
    t.string "camera_operator_name"
    t.string "plane_name"
    t.string "camera_name"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.boolean "nri", default: false, null: false
    t.boolean "sl", default: false, null: false
    t.boolean "naip", default: false, null: false
    t.boolean "associated", default: false, null: false
    t.decimal "centroid_latitude", precision: 11, scale: 8
    t.decimal "centroid_longitude", precision: 11, scale: 8
    t.text "notes"
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.bigint "upload_id"
    t.bigint "camera_id"
    t.bigint "plane_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "utm_id"
    t.bigint "project_state_id"
    t.bigint "vector_metadatum_id"
    t.bigint "flown_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["camera_id"], name: "index_rejected_footprints_on_camera_id"
    t.index ["county_id"], name: "index_rejected_footprints_on_county_id"
    t.index ["flown_by_id"], name: "index_rejected_footprints_on_flown_by_id"
    t.index ["geom"], name: "index_rejected_footprints_on_geom", using: :gist
    t.index ["plane_id"], name: "index_rejected_footprints_on_plane_id"
    t.index ["project"], name: "index_rejected_footprints_on_project"
    t.index ["project_state_id"], name: "index_rejected_footprints_on_project_state_id"
    t.index ["project_state_name"], name: "index_rejected_footprints_on_project_state_name"
    t.index ["rejected_date"], name: "index_rejected_footprints_on_rejected_date"
    t.index ["rejection_type"], name: "index_rejected_footprints_on_rejection_type"
    t.index ["state_id"], name: "index_rejected_footprints_on_state_id"
    t.index ["upload_id"], name: "index_rejected_footprints_on_upload_id"
    t.index ["utm_id"], name: "index_rejected_footprints_on_utm_id"
    t.index ["vector_metadatum_id"], name: "index_rejected_footprints_on_vector_metadatum_id"
  end

  create_table "rejected_frame_centers", force: :cascade do |t|
    t.date "rejected_date"
    t.bigint "original_id"
    t.string "rejection_type"
    t.string "project"
    t.string "strip_frame"
    t.string "project_state_name"
    t.decimal "gpstime"
    t.decimal "x"
    t.decimal "y"
    t.decimal "z"
    t.decimal "omega"
    t.decimal "phi"
    t.decimal "kappa"
    t.datetime "flight_date"
    t.decimal "sun_angle", precision: 10, scale: 3
    t.boolean "sun_angle_error", default: false, null: false
    t.text "notes"
    t.text "review_desc"
    t.string "flown_by_name"
    t.string "flown_by_alias"
    t.string "camera_name"
    t.string "plane_name"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.boolean "nri", default: false, null: false
    t.boolean "sl", default: false, null: false
    t.boolean "naip", default: false, null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.boolean "build_geom", default: false, null: false
    t.integer "footprint_id"
    t.geography "geom", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.bigint "rejected_footprint_id"
    t.bigint "upload_id"
    t.bigint "flown_by_id"
    t.bigint "camera_id"
    t.bigint "plane_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "project_state_id"
    t.bigint "utm_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "strip"
    t.index ["camera_id"], name: "index_rejected_frame_centers_on_camera_id"
    t.index ["county_id"], name: "index_rejected_frame_centers_on_county_id"
    t.index ["flown_by_id"], name: "index_rejected_frame_centers_on_flown_by_id"
    t.index ["footprint_id"], name: "index_rejected_frame_centers_on_footprint_id"
    t.index ["geom"], name: "index_rejected_frame_centers_on_geom", using: :gist
    t.index ["plane_id"], name: "index_rejected_frame_centers_on_plane_id"
    t.index ["project"], name: "index_rejected_frame_centers_on_project"
    t.index ["project_state_id"], name: "index_rejected_frame_centers_on_project_state_id"
    t.index ["project_state_name"], name: "index_rejected_frame_centers_on_project_state_name"
    t.index ["rejected_date"], name: "index_rejected_frame_centers_on_rejected_date"
    t.index ["rejected_footprint_id"], name: "index_rejected_frame_centers_on_rejected_footprint_id"
    t.index ["rejection_type"], name: "index_rejected_frame_centers_on_rejection_type"
    t.index ["state_id"], name: "index_rejected_frame_centers_on_state_id"
    t.index ["strip_frame"], name: "index_rejected_frame_centers_on_strip_frame"
    t.index ["upload_id"], name: "index_rejected_frame_centers_on_upload_id"
    t.index ["utm_id"], name: "index_rejected_frame_centers_on_utm_id"
  end

  create_table "rejected_tile_footprints", force: :cascade do |t|
    t.string "strip_frame"
    t.date "flight_date", null: false
    t.integer "original_footprint_id"
    t.bigint "tile_id"
    t.bigint "camera_id"
    t.bigint "flown_by_id"
    t.bigint "rejected_tile_id"
    t.bigint "rejected_footprint_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["camera_id"], name: "index_rejected_tile_footprints_on_camera_id"
    t.index ["flight_date"], name: "index_rejected_tile_footprints_on_flight_date"
    t.index ["flown_by_id"], name: "index_rejected_tile_footprints_on_flown_by_id"
    t.index ["rejected_footprint_id"], name: "index_rejected_tile_footprints_on_rejected_footprint_id"
    t.index ["rejected_tile_id"], name: "index_rejected_tile_footprints_on_rejected_tile_id"
    t.index ["strip_frame"], name: "index_rejected_tile_footprints_on_strip_frame"
    t.index ["tile_id"], name: "index_rejected_tile_footprints_on_tile_id"
  end

  create_table "rejected_tiles", force: :cascade do |t|
    t.date "rejected_date"
    t.date "rejection_report_date"
    t.string "rejection_type"
    t.integer "number"
    t.string "filename"
    t.string "project", null: false
    t.string "project_no"
    t.string "project_state_name", null: false
    t.string "phase", null: false
    t.string "asi_block"
    t.string "usda_region"
    t.string "psn"
    t.decimal "area"
    t.decimal "easements_acres"
    t.string "poly_id", null: false
    t.string "line_id"
    t.string "at_block"
    t.date "flight_date"
    t.date "county_flown_date"
    t.date "county_due_date"
    t.datetime "median_flight_date_time"
    t.date "report_date"
    t.date "ortho_proc_date"
    t.date "dump_date"
    t.date "ship_date"
    t.date "at_start_date"
    t.date "at_done_date"
    t.date "asi_rejected_date"
    t.date "usda_accepted_date"
    t.date "usda_rejected_date"
    t.date "production_upload_date"
    t.date "invoiced_date"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.string "flown_by_alias"
    t.string "flown_by_name"
    t.string "pilot"
    t.string "sensor_operator"
    t.string "plane_name"
    t.string "camera_name"
    t.integer "rows"
    t.integer "columns"
    t.text "notes"
    t.text "review_desc"
    t.bigint "easement_id"
    t.bigint "camera_id"
    t.bigint "plane_id"
    t.bigint "packing_slip_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "project_state_id"
    t.bigint "utm_id"
    t.bigint "time_zone_id"
    t.bigint "flown_by_id"
    t.bigint "vector_metadatum_id"
    t.bigint "tile_id"
    t.geography "geom", limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contract_award_id"
    t.bigint "production_rate_id"
    t.bigint "flight_rate_id"
    t.decimal "flight_amount", precision: 18, scale: 9
    t.decimal "production_amount", precision: 18, scale: 9
    t.decimal "total_amount", precision: 18, scale: 9
    t.decimal "sub_flight_cost", precision: 18, scale: 9, default: "0.0"
    t.decimal "sub_production_cost", precision: 18, scale: 9, default: "0.0"
    t.decimal "sub_total_cost", precision: 18, scale: 9, default: "0.0"
    t.index ["asi_rejected_date"], name: "index_rejected_tiles_on_asi_rejected_date"
    t.index ["at_block"], name: "index_rejected_tiles_on_at_block"
    t.index ["at_done_date"], name: "index_rejected_tiles_on_at_done_date"
    t.index ["at_start_date"], name: "index_rejected_tiles_on_at_start_date"
    t.index ["camera_id"], name: "index_rejected_tiles_on_camera_id"
    t.index ["contract_award_id"], name: "index_rejected_tiles_on_contract_award_id"
    t.index ["county_due_date"], name: "index_rejected_tiles_on_county_due_date"
    t.index ["county_flown_date"], name: "index_rejected_tiles_on_county_flown_date"
    t.index ["county_id"], name: "index_rejected_tiles_on_county_id"
    t.index ["dump_date"], name: "index_rejected_tiles_on_dump_date"
    t.index ["easement_id"], name: "index_rejected_tiles_on_easement_id"
    t.index ["filename"], name: "index_rejected_tiles_on_filename"
    t.index ["flight_date"], name: "index_rejected_tiles_on_flight_date"
    t.index ["flight_rate_id"], name: "index_rejected_tiles_on_flight_rate_id"
    t.index ["flown_by_id"], name: "index_rejected_tiles_on_flown_by_id"
    t.index ["geom"], name: "index_rejected_tiles_on_geom", using: :gist
    t.index ["invoiced_date"], name: "index_rejected_tiles_on_invoiced_date"
    t.index ["median_flight_date_time"], name: "index_rejected_tiles_on_median_flight_date_time"
    t.index ["ortho_proc_date"], name: "index_rejected_tiles_on_ortho_proc_date"
    t.index ["packing_slip_id"], name: "index_rejected_tiles_on_packing_slip_id"
    t.index ["phase"], name: "index_rejected_tiles_on_phase"
    t.index ["plane_id"], name: "index_rejected_tiles_on_plane_id"
    t.index ["poly_id"], name: "index_rejected_tiles_on_poly_id"
    t.index ["production_rate_id"], name: "index_rejected_tiles_on_production_rate_id"
    t.index ["production_upload_date"], name: "index_rejected_tiles_on_production_upload_date"
    t.index ["project"], name: "index_rejected_tiles_on_project"
    t.index ["project_no"], name: "index_rejected_tiles_on_project_no"
    t.index ["project_state_id"], name: "index_rejected_tiles_on_project_state_id"
    t.index ["project_state_name"], name: "index_rejected_tiles_on_project_state_name"
    t.index ["rejected_date"], name: "index_rejected_tiles_on_rejected_date"
    t.index ["rejection_report_date"], name: "index_rejected_tiles_on_rejection_report_date"
    t.index ["rejection_type"], name: "index_rejected_tiles_on_rejection_type"
    t.index ["report_date"], name: "index_rejected_tiles_on_report_date"
    t.index ["ship_date"], name: "index_rejected_tiles_on_ship_date"
    t.index ["state_id"], name: "index_rejected_tiles_on_state_id"
    t.index ["tile_id"], name: "index_rejected_tiles_on_tile_id"
    t.index ["time_zone_id"], name: "index_rejected_tiles_on_time_zone_id"
    t.index ["usda_accepted_date"], name: "index_rejected_tiles_on_usda_accepted_date"
    t.index ["usda_rejected_date"], name: "index_rejected_tiles_on_usda_rejected_date"
    t.index ["utm_id"], name: "index_rejected_tiles_on_utm_id"
    t.index ["vector_metadatum_id"], name: "index_rejected_tiles_on_vector_metadatum_id"
  end

  create_table "report_histories", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_report_histories_on_name"
    t.index ["user_id"], name: "index_report_histories_on_user_id"
  end

  create_table "states", force: :cascade do |t|
    t.string "fips"
    t.string "abv"
    t.string "name"
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abv"], name: "index_states_on_abv"
    t.index ["fips"], name: "index_states_on_fips"
    t.index ["name"], name: "index_states_on_name"
  end

  create_table "tile_footprints", force: :cascade do |t|
    t.bigint "tile_id"
    t.bigint "footprint_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["footprint_id"], name: "index_tile_footprints_on_footprint_id"
    t.index ["tile_id"], name: "index_tile_footprints_on_tile_id"
  end

  create_table "tiles", force: :cascade do |t|
    t.integer "number"
    t.string "filename"
    t.string "project", null: false
    t.string "project_no"
    t.string "project_state_name", null: false
    t.string "phase", null: false
    t.string "asi_block"
    t.string "usda_region"
    t.string "psn"
    t.decimal "area"
    t.decimal "easements_acres"
    t.string "poly_id", null: false
    t.string "line_id"
    t.string "at_block"
    t.date "flight_date"
    t.date "county_flown_date"
    t.date "county_due_date"
    t.datetime "median_flight_date_time"
    t.date "report_date"
    t.date "ortho_proc_date"
    t.date "dump_date"
    t.date "ship_date"
    t.date "at_start_date"
    t.date "at_done_date"
    t.date "asi_rejected_date"
    t.date "usda_accepted_date"
    t.date "usda_rejected_date"
    t.date "production_upload_date"
    t.date "invoiced_date"
    t.string "county_name"
    t.string "state_name"
    t.string "state_abv"
    t.string "utm_zone"
    t.string "flown_by_alias"
    t.string "flown_by_name"
    t.string "pilot"
    t.string "sensor_operator"
    t.string "plane_name"
    t.string "camera_name"
    t.boolean "covered", default: false, null: false
    t.integer "rows"
    t.integer "columns"
    t.text "notes"
    t.text "review_desc"
    t.bigint "easement_id"
    t.bigint "camera_id"
    t.bigint "plane_id"
    t.bigint "packing_slip_id"
    t.bigint "county_id"
    t.bigint "state_id"
    t.bigint "project_state_id"
    t.bigint "utm_id"
    t.bigint "time_zone_id"
    t.bigint "flown_by_id"
    t.bigint "upload_id"
    t.bigint "vector_metadatum_id"
    t.geography "geom", limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contract_award_id"
    t.bigint "production_rate_id"
    t.bigint "flight_rate_id"
    t.decimal "flight_amount", precision: 18, scale: 9
    t.decimal "production_amount", precision: 18, scale: 9
    t.decimal "total_amount", precision: 18, scale: 9
    t.date "associate_date"
    t.decimal "sub_flight_cost", precision: 18, scale: 9, default: "0.0"
    t.decimal "sub_production_cost", precision: 18, scale: 9, default: "0.0"
    t.decimal "sub_total_cost", precision: 18, scale: 9, default: "0.0"
    t.index ["asi_rejected_date"], name: "index_tiles_on_asi_rejected_date"
    t.index ["at_block"], name: "index_tiles_on_at_block"
    t.index ["at_done_date"], name: "index_tiles_on_at_done_date"
    t.index ["at_start_date"], name: "index_tiles_on_at_start_date"
    t.index ["camera_id"], name: "index_tiles_on_camera_id"
    t.index ["contract_award_id"], name: "index_tiles_on_contract_award_id"
    t.index ["county_due_date"], name: "index_tiles_on_county_due_date"
    t.index ["county_flown_date"], name: "index_tiles_on_county_flown_date"
    t.index ["county_id"], name: "index_tiles_on_county_id"
    t.index ["dump_date"], name: "index_tiles_on_dump_date"
    t.index ["easement_id"], name: "index_tiles_on_easement_id"
    t.index ["easements_acres"], name: "index_tiles_on_easements_acres"
    t.index ["filename"], name: "index_tiles_on_filename"
    t.index ["flight_date"], name: "index_tiles_on_flight_date"
    t.index ["flight_rate_id"], name: "index_tiles_on_flight_rate_id"
    t.index ["flown_by_id"], name: "index_tiles_on_flown_by_id"
    t.index ["geom"], name: "index_tiles_on_geom", using: :gist
    t.index ["invoiced_date"], name: "index_tiles_on_invoiced_date"
    t.index ["median_flight_date_time"], name: "index_tiles_on_median_flight_date_time"
    t.index ["ortho_proc_date"], name: "index_tiles_on_ortho_proc_date"
    t.index ["packing_slip_id"], name: "index_tiles_on_packing_slip_id"
    t.index ["phase"], name: "index_tiles_on_phase"
    t.index ["plane_id"], name: "index_tiles_on_plane_id"
    t.index ["poly_id"], name: "index_tiles_on_poly_id"
    t.index ["production_rate_id"], name: "index_tiles_on_production_rate_id"
    t.index ["production_upload_date"], name: "index_tiles_on_production_upload_date"
    t.index ["project"], name: "index_tiles_on_project"
    t.index ["project_no"], name: "index_tiles_on_project_no"
    t.index ["project_state_id"], name: "index_tiles_on_project_state_id"
    t.index ["project_state_name"], name: "index_tiles_on_project_state_name"
    t.index ["report_date"], name: "index_tiles_on_report_date"
    t.index ["ship_date"], name: "index_tiles_on_ship_date"
    t.index ["state_id"], name: "index_tiles_on_state_id"
    t.index ["time_zone_id"], name: "index_tiles_on_time_zone_id"
    t.index ["upload_id"], name: "index_tiles_on_upload_id"
    t.index ["usda_accepted_date"], name: "index_tiles_on_usda_accepted_date"
    t.index ["usda_rejected_date"], name: "index_tiles_on_usda_rejected_date"
    t.index ["utm_id"], name: "index_tiles_on_utm_id"
    t.index ["vector_metadatum_id"], name: "index_tiles_on_vector_metadatum_id"
  end

  create_table "time_zones", force: :cascade do |t|
    t.string "name", null: false
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["geom"], name: "index_time_zones_on_geom", using: :gist
  end

  create_table "uploads", force: :cascade do |t|
    t.integer "number_uploaded", default: 0
    t.string "folder_path"
    t.bigint "uploader_id"
    t.string "upload_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uploader_id"], name: "index_uploads_on_uploader_id"
  end

  create_table "uptime_logs", force: :cascade do |t|
    t.string "project"
    t.string "location"
    t.datetime "logged_at"
    t.string "status"
    t.integer "dns_response_time"
    t.integer "ssl_handshake_time"
    t.integer "connection_time"
    t.integer "response_time"
    t.string "reason"
    t.bigint "upload_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location", "response_time", "logged_at"], name: "index_uptime_logs_on_location_and_response_time_and_logged_at", unique: true
    t.index ["logged_at"], name: "index_uptime_logs_on_logged_at"
    t.index ["project"], name: "index_uptime_logs_on_project"
    t.index ["response_time"], name: "index_uptime_logs_on_response_time"
    t.index ["status"], name: "index_uptime_logs_on_status"
    t.index ["upload_id"], name: "index_uptime_logs_on_upload_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.string "role"
    t.boolean "approved", default: true, null: false
    t.boolean "marked_as_destroyed", default: false, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "remember_token"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "utms", force: :cascade do |t|
    t.integer "swlon"
    t.integer "swlat"
    t.string "hemisphere"
    t.integer "zone"
    t.geography "geom", limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vector_metadata", force: :cascade do |t|
    t.string "project"
    t.string "service_name"
    t.string "state_name"
    t.integer "count"
    t.text "shapefile_path"
    t.date "flight_date"
    t.date "provisional_date"
    t.date "provisional_due_date"
    t.date "production_date"
    t.date "production_due_date"
    t.bigint "state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_date"], name: "index_vector_metadata_on_flight_date"
    t.index ["production_date"], name: "index_vector_metadata_on_production_date"
    t.index ["production_due_date"], name: "index_vector_metadata_on_production_due_date"
    t.index ["project"], name: "index_vector_metadata_on_project"
    t.index ["provisional_date"], name: "index_vector_metadata_on_provisional_date"
    t.index ["provisional_due_date"], name: "index_vector_metadata_on_provisional_due_date"
    t.index ["state_id"], name: "index_vector_metadata_on_state_id"
  end

  create_table "web_log_summaries", force: :cascade do |t|
    t.string "project"
    t.date "log_date"
    t.string "service"
    t.string "ip_address"
    t.string "domain"
    t.integer "count"
    t.bigint "vector_metadatum_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_web_log_summaries_on_domain"
    t.index ["ip_address"], name: "index_web_log_summaries_on_ip_address"
    t.index ["log_date"], name: "index_web_log_summaries_on_log_date"
    t.index ["project"], name: "index_web_log_summaries_on_project"
    t.index ["service"], name: "index_web_log_summaries_on_service"
    t.index ["vector_metadatum_id"], name: "index_web_log_summaries_on_vector_metadatum_id"
  end

  create_table "web_log_uploads", force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "count"
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_web_log_uploads_on_end_date"
    t.index ["start_date"], name: "index_web_log_uploads_on_start_date"
  end

  create_table "web_logs", force: :cascade do |t|
    t.string "project"
    t.string "service"
    t.datetime "logged_at"
    t.string "ip_address"
    t.string "domain"
    t.integer "bytes"
    t.decimal "total_time", precision: 5, scale: 2
    t.integer "status"
    t.string "source"
    t.string "path"
    t.bigint "web_log_upload_id"
    t.bigint "vector_metadatum_id"
    t.bigint "web_log_summary_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bytes"], name: "index_web_logs_on_bytes"
    t.index ["domain"], name: "index_web_logs_on_domain"
    t.index ["ip_address"], name: "index_web_logs_on_ip_address"
    t.index ["logged_at", "service", "project"], name: "index_web_logs_on_logged_at_and_service_and_project"
    t.index ["logged_at"], name: "index_web_logs_on_logged_at"
    t.index ["service"], name: "index_web_logs_on_service"
    t.index ["status"], name: "index_web_logs_on_status"
    t.index ["total_time"], name: "index_web_logs_on_total_time"
    t.index ["vector_metadatum_id"], name: "index_web_logs_on_vector_metadatum_id"
    t.index ["web_log_summary_id"], name: "index_web_logs_on_web_log_summary_id"
    t.index ["web_log_upload_id"], name: "index_web_logs_on_web_log_upload_id"
  end

end
