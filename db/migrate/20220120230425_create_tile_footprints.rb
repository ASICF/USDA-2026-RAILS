class CreateTileFootprints < ActiveRecord::Migration[5.2]
  def change
    create_table :tile_footprints do |t|
      t.belongs_to :tile
      t.belongs_to :footprint
      t.timestamps
    end
  end
end
