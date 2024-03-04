class CreatePhotoIndices < ActiveRecord::Migration[5.2]
  def change
    create_table :photo_indices do |t|
      t.string :project, nil: false
      t.string :strip, nil: false
      t.string :frame, nil: false
      t.string :strip_frame, index: true, nil: false
      t.string :flown_by_name, nil: false
      t.string :camera_name, nil: false
      t.string :county_name
      t.string :state_name
      t.string :utm_zone
      t.boolean :nri, default: false, null: false
      t.boolean :sl, default: false, null: false
      t.boolean :naip, default: false, null: false
      t.date :flight_date, nil: false
      t.datetime :flight_date_time, nil: false
      t.decimal :gpstime
      t.decimal :sun_angle, precision: 10, scale: 3, index: true
      t.boolean :sun_angle_error, null: false, default: false
      t.decimal :recorded_sun_angle, precision: 10, scale: 3
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :notes, index: true
      t.st_point :geom, geographic: true
      t.references :footprint
      t.references :rejected_footprint
      t.references :upload
      t.references :flown_by
      t.references :county
      t.references :state
      t.references :utm
      t.references :camera
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end
