class CreateCameras < ActiveRecord::Migration[5.1]
  def change
    create_table :cameras do |t|
      t.string :name, null: false
      t.string :manufacturer
      t.string :model
      t.string :serial_number
      # t.decimal :amount, null: false, default: 0.0, precision: 8, scale: 2
      t.date :manufactured_date
      t.boolean :sl, default: true, null: false
      t.boolean :nri, default: true, null: false
      t.boolean :naip, default: true, null: false
      t.references :company
      t.timestamps
    end
  end
end
