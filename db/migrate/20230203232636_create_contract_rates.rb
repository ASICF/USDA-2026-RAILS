class CreateContractRates < ActiveRecord::Migration[5.2]
  def change
    create_table :contract_rates do |t|
      t.string :project, index: true
      t.string :project_no, index: true
      t.string :company_alias, index: true
      t.string :phase, nil: false
      t.decimal :amount, precision: 4, scale: 2, nil: false
      t.date :start_date, nil: false
      t.date :end_date, nil: false
      t.references :state
      t.references :company
      t.timestamps
    end
  end
end
