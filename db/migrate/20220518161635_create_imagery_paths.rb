class CreateImageryPaths < ActiveRecord::Migration[5.2]
  def change
    create_table :imagery_paths do |t|
      t.string :project, index: true
      t.text :path
      t.references :pathable, polymorphic: true
      t.references :user
      t.timestamps
    end
  end
end
