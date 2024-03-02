class CreateFrameCenters < ActiveRecord::Migration[5.1]
  def change
    create_table :frame_centers do |t|
      t.string :project, index: true
      t.string :strip, index: true
      t.string :strip_frame, index: true
      t.string :project_state_name, index: true
      t.decimal :gpstime, precision: 11, scale: 5
      t.decimal :x, precision: 11, scale: 3
      t.decimal :y, precision: 11, scale: 3
      t.decimal :z, precision: 10, scale: 3
      t.decimal :omega, precision: 10, scale: 5
      t.decimal :phi, precision: 10, scale: 5
      t.decimal :kappa, precision: 10, scale: 5
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
      t.decimal :latitude, precision: 11, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.boolean :build_geom, null: false, default: false
      t.st_point :geom, geographic: true
      t.references :footprint
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
