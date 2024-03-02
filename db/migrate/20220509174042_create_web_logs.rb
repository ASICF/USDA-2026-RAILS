class CreateWebLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :web_logs do |t|
      t.string :project, nil: false
      t.string :service, index: true
      t.datetime :logged_at, index: true
      t.string :ip_address, index: true
      t.string :domain, index: true
      t.integer :bytes, index: true
      t.decimal :total_time, precision: 5, scale: 2, index: true
      t.integer :status, index: true
      t.string :source, nil: false
      t.string :path, nil: false
      t.references :web_log_upload
      t.references :vector_metadatum
      t.references :web_log_summary
      t.index [:logged_at, :service, :project]
      t.timestamps
    end
  end
end
