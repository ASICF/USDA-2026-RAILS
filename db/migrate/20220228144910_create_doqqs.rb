class CreateDoqqs < ActiveRecord::Migration[5.2]
  def change
    create_table :doqqs do |t|
      t.string :filename, index: true
      t.string :project_state_name, index: true, null: false
      t.string :project_no, index: true
      # t.string :phase, index: true, null: false

      t.string :apfo_name, index: true
      t.string :qq_apfo_name, index: true
      t.string :quadrant, index: true
      t.string :quad_state_abvs
      # t.string :zone, index: true
    
      t.string :film_type
      t.string :q_lat
      t.string :q_lon
      t.string :loc
      t.string :gsd
      t.string :q_key, index: true, null: false
      t.string :qq_name, index: true
      t.decimal :acres, index: true
      t.decimal :sq_miles, index: true
      t.integer :rows
      t.integer :columns

      t.string :psn
      t.date :flight_date, index: true
      t.datetime :median_flight_date_time, index: true
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
      t.string :flown_by_name
      t.string :pilot
      t.string :sensor_operator
      t.string :plane_name
      t.string :camera_name
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.text :notes
      t.text :review_desc
      t.string :counties, index: true
      t.references :camera
      t.references :plane
      t.references :packing_slip
      t.references :county
      t.references :state
      t.references :project_state
      t.references :utm
      t.references :flown_by
      t.references :upload
      t.references :vector_metadatum
      t.multi_polygon :geom, geographic: true
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end

# class CreateDoqqs < ActiveRecord::Migration[5.2]
#   def change
#     create_table :doqqs do |t|
#       t.string :filename, index: true
#       t.string :project_no, index: true, null: false
#       t.string :phase, index: true, null: false

#       # t.integer :apfobase_a
#       t.string :perimeter
#       t.integer :all_doqq
#       t.integer :all_doqq_id
#       t.decimal :x_coord, precision: 5, scale: 5
#       t.decimal :y_coord, precision: 5, scale: 5
#       # t.bigint :QID
#       t.string :state_abv
#       t.string :q_name
#       t.string :lat
#       t.string :long
#       t.string :q_key
#       t.string :quadrant
#       t.string :se_coords
#       t.string :f_quad_name
#       t.string :quad_state_abv
#       t.string :apfo_name
#       t.integer :utm_zone
#       t.string :cir_name
#       t.string :bw_name
#       t.integer :map_no 
#       t.string :gnis
#       t.string :dy
#       t.string :my
#       t.string :sy
#       t.string :dx
#       t.string :mx
#       t.string :sx
#       t.string :o_lat
#       t.string :o_long
#       t.string :cir
#       t.string :bw
#       t.string :qq_apfo_name
#       t.decimal :shape_area, precision: 2, scale: 12
#       t.decimal :shape_length, precision: 2, scale: 12
#       t.integer :original_id
#       t.string :station
#       t.string :latitude_dms
#       t.string :longitude_dms
#       t.decimal :latitude_dd, precision: 3, scale: 5
#       t.decimal :longitude_dd, precision: 3, scale: 5
#       # t.string :ARCKEY
#       t.bigint :altitude
#       t.decimal :distance, precision: 10, scale: 12
#       t.decimal :area_sq_miles, precision: 2, scale: 12

#       # t.string :film_type
#       # t.string :q_lat
#       # t.string :q_lon
#       # t.string :quadrant
#       # t.string :loc
#       # t.string :gsd
#       # t.string :q_key, index: true, null: false
#       # t.string :qq_name, index: true

#       t.string :psn
#       t.date :flight_date, index: true
#       t.datetime :median_flight_date_time, index: true
#       t.date :ortho_proc_date, index: true
#       t.date :dump_date, index: true
#       t.date :ship_date, index: true
#       t.date :at_start_date, index: true
#       t.date :at_done_date, index: true
#       t.date :asi_rejected_date, index: true
#       t.date :usda_accepted_date, index: true
#       t.date :usda_rejected_date, index: true
#       t.string :county_name
#       # t.string :state_name
#       t.string :utm_zone
#       # t.string :flown_by_name
#       # t.string :pilot
#       # t.string :sensor_operator
#       # t.string :plane_name
#       # t.string :camera_name
#       t.decimal :latitude, precision: 10, scale: 6
#       t.decimal :longitude, precision: 10, scale: 6
#       t.text :notes
#       t.text :review_desc
#       # t.references :camera
#       # t.references :plane
#       t.references :packing_slip
#       t.references :county
#       t.references :state
#       t.references :utm
#       # t.references :flown_by
#       t.references :upload
#       t.multi_polygon :geom, geographic: true
#       t.timestamps
#       t.index :geom, using: :gist
#     end
#   end
# end
