class AddStartEndDateToEasements < ActiveRecord::Migration[5.2]
  def change
    add_column :easements, :start_date, :date
    add_column :easements, :end_date, :date
  end
end