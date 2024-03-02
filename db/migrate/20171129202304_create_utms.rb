class CreateUtms < ActiveRecord::Migration[5.1]
  def change
    create_table :utms do |t|
      t.integer :swlon
      t.integer :swlat
      t.string :hemisphere
      t.integer :zone
      t.multi_polygon :geom, geographic: true, using: :gist
      t.timestamps
    end
  end
end
