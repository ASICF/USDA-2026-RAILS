class AddPlanesToPhotoIndex < ActiveRecord::Migration[5.2]
  def change
    add_column :photo_indices, :plane_name, :string, index: true
    add_reference :photo_indices, :plane, index: true
  end
end
