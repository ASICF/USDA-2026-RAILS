# class AddAssociationToPhotoIndex < ActiveRecord::Migration[5.2]
#   def change
#     add_column :photo_indices, :utm_zone, :string 
#     add_column :photo_indices, :county_name, :string 
#     add_column :photo_indices, :state_name, :string 
#     add_reference :photo_indices, :utm, index: true
#     add_reference :photo_indices, :county, index: true
#     add_reference :photo_indices, :state, index: true
#   end
# end
