class CreateUploads < ActiveRecord::Migration[5.1]
  def change
    create_table :uploads do |t|
      t.integer :number_uploaded, default: 0
      t.string :folder_path
      t.references :uploader
      t.string :upload_type
      t.timestamps
    end
  end
end
