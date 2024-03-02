class CreateReportHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :report_histories do |t|
      t.string :name, index: true
      t.references :user
      t.timestamps
    end
  end
end
