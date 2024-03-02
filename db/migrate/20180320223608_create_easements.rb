class CreateEasements < ActiveRecord::Migration[5.1]
  def change
    create_table :easements do |t|
      t.string :poly_id, index: true, null: false
      t.string :original_poly_id, index: true, null: false
      t.string :project, index: true, null: false
      t.string :project_no, index: true
      t.string :project_state_name, index: true, null: false
      t.string :phase
      t.date :flight_date, index: true
      t.string :scale
      t.decimal :acres, index: true
      t.decimal :buffer_acres
      t.string :asi_block
      t.string :status
      t.string :usda_region
      t.string :county_name
      t.string :state_name
      t.string :state_abv
      t.string :utm_zone
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :original_fid, bigint: true
      t.multi_polygon :geom, geographic: true
      t.references :upload
      t.references :county
      t.references :state
      t.references :project_state
      t.references :utm
      t.references :time_zone
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end

# t.string :field_id, index: true
# t.string :poly_id, index: true, null: false
# t.string :project, index: true, null: false, index: true
# t.date :flight_date, index: true
# t.string :project_no, index: true
# # SL
# t.string :scale
# t.decimal :acres, index: true
# t.string :buffer_distance
# t.decimal :buffer_acres, index: true
# t.string :region
# # NRI
# t.date :start_date, index: true
# t.date :end_date, index: true
# t.integer :elevation
# t.decimal :acres, index: true
# t.string :asi_block
# t.string :full_fips
# t.string :county_name
# t.string :state_name
# t.string :utm_zone
# t.decimal :latitude, precision: 10, scale: 6
# t.decimal :longitude, precision: 10, scale: 6
# t.multi_polygon :geom, geographic: true
# t.references :upload
# t.references :county
# t.references :state
# t.references :utm
# t.timestamps
# t.index :geom, using: :gist