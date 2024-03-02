class FixCostPrecisionScale < ActiveRecord::Migration[5.2]
  def up
    # Tiles
    remove_column :tiles, :flight_cost
    remove_column :tiles, :production_cost
    remove_column :tiles, :total_cost
    add_column :tiles, :flight_amount, :decimal, precision: 18, scale: 9
    add_column :tiles, :production_amount, :decimal, precision: 18, scale: 9
    add_column :tiles, :total_amount, :decimal, precision: 18, scale: 9

    # Rejected Tiles
    remove_column :rejected_tiles, :flight_cost
    remove_column :rejected_tiles, :production_cost
    remove_column :rejected_tiles, :total_cost
    add_column :rejected_tiles, :flight_amount, :decimal, precision: 18, scale: 9
    add_column :rejected_tiles, :production_amount, :decimal, precision: 18, scale: 9
    add_column :rejected_tiles, :total_amount, :decimal, precision: 18, scale: 9
    
    # Contract Rates
    remove_column :contract_rates, :amount
    add_column :contract_rates, :cost, :decimal, precision: 10, scale: 9
  end

  def down
    # Tiles
    remove_column :tiles, :flight_amount
    remove_column :tiles, :production_amount
    remove_column :tiles, :total_amount
    add_column :tiles, :flight_cost, :decimal, precision: 9, scale: 2
    add_column :tiles, :production_cost, :decimal, precision: 9, scale: 2
    add_column :tiles, :total_cost, :decimal, precision: 9, scale: 2
    
    # Tiles
    remove_column :rejected_tiles, :flight_amount
    remove_column :rejected_tiles, :production_amount
    remove_column :rejected_tiles, :total_amount
    add_column :rejected_tiles, :flight_cost, :decimal, precision: 9, scale: 2
    add_column :rejected_tiles, :production_cost, :decimal, precision: 9, scale: 2
    add_column :rejected_tiles, :total_cost, :decimal, precision: 9, scale: 2
  
    # Contract Rates
    remove_column :contract_rates, :cost
    add_column :contract_rates, :amount, :decimal, precision: 4, scale: 2
  end
end