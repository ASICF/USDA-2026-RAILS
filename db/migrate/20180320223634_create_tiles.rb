class CreateTiles < ActiveRecord::Migration[5.1]
  def change
    create_table :tiles do |t|
      t.integer :number
      t.string :filename, index: true
      t.string :project, index: true, null: false
      t.string :project_no, index: true
      t.string :project_state_name, index: true, null: false
      t.string :phase, index: true, null: false
      t.string :asi_block
      t.string :usda_region
      t.string :psn
      t.decimal :area
      t.decimal :easements_acres, index: true
      t.string :poly_id, index: true, null: false
      t.string :line_id
      t.string :at_block, index: true
      t.date :flight_date, index: true
      t.date :county_flown_date, index: true
      t.date :county_due_date, index: true
      t.datetime :median_flight_date_time, index: true
      t.date :report_date, index: true
      t.date :ortho_proc_date, index: true
      t.date :dump_date, index: true
      t.date :ship_date, index: true
      t.date :at_start_date, index: true
      t.date :at_done_date, index: true
      t.date :asi_rejected_date, index: true
      t.date :usda_accepted_date, index: true
      t.date :usda_rejected_date, index: true
      t.date :production_upload_date, index: true
      t.date :invoiced_date, index: true
      t.string :county_name
      t.string :state_name
      t.string :state_abv
      t.string :utm_zone
      t.string :flown_by_alias
      t.string :flown_by_name
      t.string :pilot
      t.string :sensor_operator
      t.string :plane_name
      t.string :camera_name
      t.boolean :covered, null: false, default: false
      t.integer :rows
      t.integer :columns
      t.text :notes
      t.text :review_desc
      t.references :easement
      t.references :camera
      t.references :plane
      t.references :packing_slip
      t.references :county
      t.references :state
      t.references :project_state
      t.references :utm
      t.references :time_zone
      t.references :flown_by
      t.references :upload
      t.references :vector_metadatum
      t.st_polygon :geom, geographic: true
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end
