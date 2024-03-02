# class AddFieldsToWebLogs < ActiveRecord::Migration[5.2]

#   def up
#     add_reference :web_log_summaries, :vector_metadatum, index: true
#     add_reference :web_logs, :vector_metadatum, index: true
#     change_column :web_logs, :total_time, :decimal, precision: 5, scale: 2, index: true
#   end
  
#   def down
#     remove_reference :web_log_summaries, :vector_metadatum
#     remove_reference :web_logs, :vector_metadatum
#     change_column :web_logs, :total_time, :integer, index: true
#   end

# end
