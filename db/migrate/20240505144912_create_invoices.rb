class CreateInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :invoices do |t|
      t.string :number, null: false
      t.date :invoice_date, null: false
      t.string :project, null: false
      t.integer :acres
      t.decimal :amount, precision: 18, scale: 9, default: 0.0
      t.timestamps
    end
  end
end
