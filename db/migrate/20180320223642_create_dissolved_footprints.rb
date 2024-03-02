class CreateDissolvedFootprints < ActiveRecord::Migration[5.1]
  def change
    create_table :dissolved_footprints do |t|
      t.string :name, null: false
      t.multi_polygon :geom, geographic: true
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end
