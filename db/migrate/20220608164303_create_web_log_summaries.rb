class CreateWebLogSummaries < ActiveRecord::Migration[5.2]
  def change
    create_table :web_log_summaries do |t|
      t.string :project, index: true
      t.date :log_date, index: true
      t.string :service, index: true
      t.string :ip_address, index: true
      t.string :domain, index: true
      t.integer :count
      t.references :vector_metadatum
      t.timestamps
    end
  end
end
