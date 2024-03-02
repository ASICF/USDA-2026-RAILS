# class UpdateCameraPlaneCompany < ActiveRecord::Migration[5.2]
#   def change
#     # Cameras
#     remove_column :cameras, :amount, :decimal
#     add_column :cameras, :sl, :boolean, default: true, null: false 
#     add_column :cameras, :naip, :boolean, default: true, null: false

#     # Planes
#     add_column :planes, :sl, :boolean, default: true, null: false 
#     add_column :planes, :naip, :boolean, default: true, null: false

#     # Companies
#     add_column :companies, :sl, :boolean, default: true, null: false 
#     add_column :companies, :naip, :boolean, default: true, null: false
#   end
# end
