class CreateBatchProcesses < ActiveRecord::Migration[5.1]
  def change
    create_table :batch_processes do |t|
      t.datetime :validate_datetime
      t.datetime :start_datetime
      t.datetime :end_datetime
      t.integer :number_of_tiffs
      t.string :input_directory
      t.string :content_file
      t.boolean :error, null: false, default: false
      t.string :message
      t.references :creator
      t.timestamps
    end
  end
end
