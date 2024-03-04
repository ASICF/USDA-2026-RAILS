class CreateRejectedFrameCenters < ActiveRecord::Migration[5.2]
  def change
    create_table :rejected_frame_centers do |t|
      t.date :rejected_date, index: true
      t.column :original_id, :bigint
      t.string :rejection_type, index: true
      t.string :project, index: true
      t.string :strip_frame, index: true
      t.string :project_state_name, index: true
      t.decimal :gpstime
      t.decimal :x
      t.decimal :y
      t.decimal :z
      t.decimal :omega
      t.decimal :phi
      t.decimal :kappa
      t.datetime :flight_date
      t.decimal :sun_angle, precision: 10, scale: 3
      t.boolean :sun_angle_error, null: false, default: false
      t.text :notes
      t.text :review_desc
      t.string :flown_by_name
      t.string :flown_by_alias
      t.string :camera_name
      t.string :plane_name
      t.string :county_name
      t.string :state_name
      t.string :state_abv
      t.string :utm_zone
      t.boolean :nri, default: false, null: false
      t.boolean :sl, default: false, null: false
      t.boolean :naip, default: false, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.boolean :build_geom, null: false, default: false
      t.integer :footprint_id, index: true
      t.st_point :geom, geographic: true
      t.references :rejected_footprint
      t.references :upload
      t.references :flown_by
      t.references :camera
      t.references :plane
      t.references :county
      t.references :state
      t.references :project_state
      t.references :utm
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end
