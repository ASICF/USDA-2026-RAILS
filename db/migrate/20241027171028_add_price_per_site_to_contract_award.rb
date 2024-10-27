class AddPricePerSiteToContractAward < ActiveRecord::Migration[5.2]
  def change
    add_column :contract_awards, :pps, :decimal, precision: 5, scale: 2, default: 0.0
  end
end
