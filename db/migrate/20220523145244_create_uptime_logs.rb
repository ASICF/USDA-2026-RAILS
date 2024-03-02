class CreateUptimeLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :uptime_logs do |t|
      t.string :project, index: true
      t.string :location
      t.datetime :logged_at, index: true
      t.string :status, index: true
      t.integer :dns_response_time
      t.integer :ssl_handshake_time
      t.integer :connection_time
      t.integer :response_time, index: true
      t.string :reason
      t.references :upload
      t.timestamps
    end

    add_index :uptime_logs, [:location, :response_time, :logged_at], unique: true
  end
end
