class CreateRejectedTileFootprints < ActiveRecord::Migration[5.2]
  def change
    create_table :rejected_tile_footprints do |t|
      t.string :strip_frame, index: true
      t.date :flight_date, null: false, index: true
      t.integer :original_footprint_id, bigint: true
      t.belongs_to :tile
      t.belongs_to :camera
      t.belongs_to :flown_by
      t.belongs_to :rejected_tile
      t.belongs_to :rejected_footprint
      t.timestamps
    end
  end
end
