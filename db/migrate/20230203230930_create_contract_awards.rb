class CreateContractAwards < ActiveRecord::Migration[5.2]
  def change
    create_table :contract_awards do |t|
      t.string :project, index: true
      t.string :project_no, index: true
      t.decimal :amount, precision: 9, scale: 2, nil: false
      t.decimal :flight_amount, precision: 9, scale: 2, nil: false
      t.decimal :production_amount, precision: 9, scale: 2, nil: false
      t.date :start_date, nil: false
      t.date :end_date, nil: false
      t.references :state
      t.timestamps
    end
  end
end
