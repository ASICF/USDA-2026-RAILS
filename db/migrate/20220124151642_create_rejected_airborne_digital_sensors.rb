class CreateRejectedAirborneDigitalSensors < ActiveRecord::Migration[5.2]
  def change
    create_table :rejected_airborne_digital_sensors do |t|
      t.date :rejected_date, index: true
      t.string :rejection_type, index: true
      t.column :original_id, :bigint
      t.string :LINEID
      t.date :at_start_date
      t.date :at_done_date
      t.boolean :covered, default: false, null: false
      t.multi_polygon :geom, geographic: true
      t.references :upload
      t.timestamps
      t.index :geom, using: :gist
    end
  end
end
