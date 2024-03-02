class CreateFootprints < ActiveRecord::Migration[5.1]
  def change
    create_table :footprints do |t|
      t.string :project, index: true
      t.string :project_state_name, index: true
      t.date :flight_date
      t.datetime :flight_date_time
      t.string :original_strip_frame
      t.string :strip_frame
      t.string :flown_by_alias
      t.string :flown_by_name
      t.string :pilot_name
      t.string :camera_operator_name
      t.string :plane_name
      t.string :camera_name
      t.string :county_name
      t.string :state_name
      t.string :state_abv
      t.string :utm_zone
      t.boolean :associated, default: false, null: false
      t.decimal :centroid_latitude, precision: 11, scale: 8
      t.decimal :centroid_longitude, precision: 11, scale: 8
      t.text :notes
      t.text :review_desc
      t.multi_polygon :geom, geographic: true
      t.references :upload
      t.references :camera
      t.references :plane
      t.references :county
      t.references :state
      t.references :utm
      t.references :project_state
      t.references :vector_metadatum
      t.references :flown_by
      t.timestamps
      t.index [:strip_frame, :flight_date, :camera_id, :flown_by_id, :project, :project_state_id], unique: true, name: :unique_strip_frame
      t.index :geom, using: :gist
    end
  end
end
