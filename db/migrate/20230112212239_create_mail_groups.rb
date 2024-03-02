class CreateMailGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :mail_groups do |t|
      t.string :name, nil: false, index: true
      t.string :description, nil: false
      t.timestamps
    end
  end
end
