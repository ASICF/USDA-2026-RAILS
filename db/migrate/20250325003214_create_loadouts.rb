class CreateLoadouts < ActiveRecord::Migration[5.2]
  def change
    create_table :loadouts do |t|
      t.string :name, null: false
      t.references :plane
      t.references :camera
      t.timestamps
    end
  end
end
