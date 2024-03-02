class CreateTimeZones < ActiveRecord::Migration[5.2]
  def change
    create_table :time_zones do |t|
      t.string :name, null: false
      t.multi_polygon :geom, geographic: true
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end
