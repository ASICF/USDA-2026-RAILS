class AddFieldsToContractAward < ActiveRecord::Migration[5.2]
  def change
    add_column :contract_awards, :season_start, :date
    add_column :contract_awards, :season_end, :date
    add_column :contract_awards, :season_extension, :date
  end
end
