class AddPpaToContractAward < ActiveRecord::Migration[5.2]
  def change
    add_column :contract_awards, :ppa, :decimal, precision: 4, scale: 2, default: 0.0
  end
end
