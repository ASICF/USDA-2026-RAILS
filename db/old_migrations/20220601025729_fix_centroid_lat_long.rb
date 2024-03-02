# class FixCentroidLatLong < ActiveRecord::Migration[5.2]

#   def self.up
#     change_table :footprints do |t|
#       t.change :centroid_latitude, :decimal, precision: 11, scale: 8, index: true
#       t.change :centroid_longitude, :decimal, precision: 11, scale: 8, index: true
#     end
#   end
#   def self.down
#     change_table :footprints do |t|
#       # Remove the Centroid Latitude/Longitude if they exist otherwise an error throws
#       execute "UPDATE footprints SET centroid_longitude = NULL, centroid_latitude = NULL" 
#       t.change :centroid_latitude, :decimal, precision: 10, scale: 8, index: true
#       t.change :centroid_longitude, :decimal, precision: 10, scale: 8, index: true
#     end
#   end

#   # def change
#   #   change_column :footprints, :centroid_latitude, :decimal, precision: 11, scale: 8, index: true
#   #   change_column :footprints, :centroid_longitude, :decimal, precision: 11, scale: 8, index: true
#   # end
# end
