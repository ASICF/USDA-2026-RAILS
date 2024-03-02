class CreateFlightTimes < ActiveRecord::Migration[5.2]
  def change
    create_table :flight_times do |t|
      t.date :flight_date, index: true
      t.datetime :start_date
      t.datetime :end_date
      t.references :tile
      t.timestamps
    end
  end
end
