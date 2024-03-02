class CreateBatchProcessLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :batch_process_logs do |t|
      t.string :filename
      t.string :file_size
      t.date :processed_date
      t.integer :rows
      t.integer :columns
      t.string :image_properties
      t.boolean :database_match, null: false, default: false
      t.boolean :folder_match, null: false, default: false
      t.boolean :error, null: false, default: false
      t.string :message
      t.references :batch_process
      t.references :tile
      t.timestamps
    end
  end
end
