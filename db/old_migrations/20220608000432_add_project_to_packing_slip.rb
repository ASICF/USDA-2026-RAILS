# class AddProjectToPackingSlip < ActiveRecord::Migration[5.2]
#   def change
#     add_column :packing_slips, :project, :string, index: true
#     add_index :packing_slips, [:name, :project], unique: true
#   end
# end
