class AddPhotoIndexAssociationToRejectedFootprints < ActiveRecord::Migration[5.2]
  def change
    add_reference :rejected_footprints, :photo_index, index: true
    add_reference :footprints, :photo_index, index: true
  end
end
