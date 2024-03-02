class CreateStates < ActiveRecord::Migration[5.1]
  def change
    create_table :states do |t|
      t.string :fips, index: true
      t.string :abv, index: true
      t.string :name, index: true
      t.multi_polygon :geom, geographic: true, using: :gist
      t.timestamps
    end
  end
end
