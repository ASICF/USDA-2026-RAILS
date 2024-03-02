class CreateJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :jobs do |t|
      t.datetime :started_at, index: true
      t.datetime :finished_at, index: true
      t.string :process_type, index: true
      t.string :filename
      t.string :message
      t.text :error_message
      t.boolean :active, null: false, default: true
      t.boolean :success, null: false, default: false
      t.integer :delayed_job_id
      t.references :upload
      t.references :creator
      t.timestamps
    end
  end
end
