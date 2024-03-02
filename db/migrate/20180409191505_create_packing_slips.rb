class CreatePackingSlips < ActiveRecord::Migration[5.1]
  def change
    create_table :packing_slips do |t|
      t.string :name
      t.string :project
      t.date :shipped_date, index: true
      t.date :approved_date, index: true
      t.date :invoiced_date, index: true
      t.timestamps
      t.index [:name, :project], unique: true
    end
  end
end
