class AddInvoiceIdToPackingSlips < ActiveRecord::Migration[5.2]
  def change
    add_column :packing_slips, :state_abv, :string, index: true
    add_reference :packing_slips, :state, index: true
    add_reference :packing_slips, :invoice, index: true
  end
end
