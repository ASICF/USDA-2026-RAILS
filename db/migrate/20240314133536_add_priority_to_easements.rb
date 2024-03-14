class AddPriorityToEasements < ActiveRecord::Migration[5.2]
  def change
    add_column :easements, :priority, :integer, default: 0
  end
end
