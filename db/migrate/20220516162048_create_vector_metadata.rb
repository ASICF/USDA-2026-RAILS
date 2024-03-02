class CreateVectorMetadata < ActiveRecord::Migration[5.2]
  def change
    create_table :vector_metadata do |t|
      t.string :project, index: true
      t.string :service_name
      t.string :state_name
      t.integer :count
      t.text :shapefile_path
      t.date :flight_date, index: true
      t.date :provisional_date, index: true
      t.date :provisional_due_date, index: true
      t.date :production_date, index: true
      t.date :production_due_date, index: true
      # t.references :metadatable, polymorphic: true
      t.references :state, index: true
      t.timestamps
    end
  end
end
