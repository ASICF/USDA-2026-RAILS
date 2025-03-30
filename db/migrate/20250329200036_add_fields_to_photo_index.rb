class AddFieldsToPhotoIndex < ActiveRecord::Migration[5.2]
  def change
    add_column :photo_indices, :has_footprint, :boolean, null: false, default: false, index: true
    add_column :photo_indices, :flown_by_alias, :string
  end
end
