class CreateCounties < ActiveRecord::Migration[5.1]
  def change
    create_table :counties do |t|
      t.string :fips, index: true
      t.string :full_fips, index: true
      t.string :name, index: true
      t.multi_polygon :geom, geographic: true, using: :gist
      t.references :state
      t.timestamps
    end
  end
end
