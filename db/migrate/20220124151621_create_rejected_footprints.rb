class CreateRejectedFootprints < ActiveRecord::Migration[5.2]
  def change
    create_table :rejected_footprints do |t|
      t.date :rejected_date, index: true
      t.string :rejection_type, index: true
      t.column :original_id, :bigint
      t.string :project, index: true
      t.string :project_state_name, index: true
      t.date :flight_date
      t.datetime :flight_date_time
      t.string :original_strip_frame
      t.string :strip_frame
      t.string :flown_by_name
      t.string :flown_by_alias
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
      t.index :geom, using: :gist
      t.timestamps
    end
  end
end
