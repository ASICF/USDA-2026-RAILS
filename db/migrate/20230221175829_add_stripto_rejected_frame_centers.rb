class AddStriptoRejectedFrameCenters < ActiveRecord::Migration[5.2]
  def change
    add_column :rejected_frame_centers, :strip, :string
  end
end
