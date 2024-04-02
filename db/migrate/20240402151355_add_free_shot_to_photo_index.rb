class AddFreeShotToPhotoIndex < ActiveRecord::Migration[5.2]
  def change
    add_column :photo_indices, :free_shot, :boolean, null: false, default: false
  end
end
