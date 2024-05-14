class CreateBufferedTiles < ActiveRecord::Migration[5.2]
  def change
    create_table :buffered_tiles do |t|
      t.string :poly_id
      t.string :filename
      t.string :state_abv
      t.st_polygon :geom, geographic: true
    end
  end
end
