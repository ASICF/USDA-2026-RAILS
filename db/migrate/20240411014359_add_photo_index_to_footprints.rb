class AddPhotoIndexToFootprints < ActiveRecord::Migration[5.2]
  def change
    add_column :footprints, :has_pi, :boolean, null: false, default: false
    add_column :rejected_footprints, :has_pi, :boolean, null: false, default: false
  end
end
