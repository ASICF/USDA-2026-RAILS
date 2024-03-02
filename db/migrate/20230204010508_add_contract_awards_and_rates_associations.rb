class AddContractAwardsAndRatesAssociations < ActiveRecord::Migration[5.2]
  def change
    # Easements
    add_reference :easements, :contract_award, index: true

    # Tiles
    add_column :tiles, :flight_cost, :decimal, precision: 9, scale: 2
    add_column :tiles, :production_cost, :decimal, precision: 9, scale: 2
    add_column :tiles, :total_cost, :decimal, precision: 9, scale: 2
    add_reference :tiles, :contract_award, index: true
    add_reference :tiles, :production_rate, index: true
    add_reference :tiles, :flight_rate, index: true

    # Rejected Tiles
    add_column :rejected_tiles, :flight_cost, :decimal, precision: 9, scale: 2
    add_column :rejected_tiles, :production_cost, :decimal, precision: 9, scale: 2
    add_column :rejected_tiles, :total_cost, :decimal, precision: 9, scale: 2
    add_reference :rejected_tiles, :contract_award, index: true
    add_reference :rejected_tiles, :production_rate, index: true
    add_reference :rejected_tiles, :flight_rate, index: true
  end
end
