class AddSubCostToContractRateTable < ActiveRecord::Migration[5.2]
  def change
    # Contract Rates
    add_column :contract_rates, :sub_cost, :decimal, precision: 10, scale: 9, default: 0.0

    # Tiles
    add_column :tiles, :sub_flight_cost, :decimal, precision: 18, scale: 9, default: 0.0
    add_column :tiles, :sub_production_cost, :decimal, precision: 18, scale: 9, default: 0.0
    add_column :tiles, :sub_total_cost, :decimal, precision: 18, scale: 9, default: 0.0

    # Rejected Tiles
    add_column :rejected_tiles, :sub_flight_cost, :decimal, precision: 18, scale: 9, default: 0.0
    add_column :rejected_tiles, :sub_production_cost, :decimal, precision: 18, scale: 9, default: 0.0
    add_column :rejected_tiles, :sub_total_cost, :decimal, precision: 18, scale: 9, default: 0.0
  end
end
