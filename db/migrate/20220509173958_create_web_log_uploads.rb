class CreateWebLogUploads < ActiveRecord::Migration[5.2]
  def change
    create_table :web_log_uploads do |t|
      t.datetime :start_date, index: true
      t.datetime :end_date, index: true
      t.integer :count
      t.string :path, nil: false
      t.timestamps
    end
  end
end
