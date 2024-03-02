class AddAssociateDateToTile < ActiveRecord::Migration[5.2]
  def change
    add_column :tiles, :associate_date, :date
  end
end
