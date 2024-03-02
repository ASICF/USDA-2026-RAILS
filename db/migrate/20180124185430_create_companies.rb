class CreateCompanies < ActiveRecord::Migration[5.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :alias
      t.boolean :sl, default: true, null: false
      t.boolean :nri, default: true, null: false
      t.boolean :naip, default: true, null: false
      t.timestamps
    end
  end
end
