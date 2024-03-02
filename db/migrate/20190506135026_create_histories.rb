class CreateHistories < ActiveRecord::Migration[5.1]
  def up
    create_table :histories do |t|
      t.string :message, index: true
      t.string :url
      t.string :file_path
      t.string :action_type, index: true
      t.text :search_terms, index: true
      t.references :creator
      t.timestamps
    end
  end

  def down
    drop_table :histories
  end
end
