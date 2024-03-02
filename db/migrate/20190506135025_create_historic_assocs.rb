class CreateHistoricAssocs < ActiveRecord::Migration[5.2]
  def change
    create_table :historic_assocs do |t|
      t.text :search_terms, index: true
      t.references :historicable, polymorphic: true, index: true
      t.references :history
      t.timestamps
    end
  end
end
