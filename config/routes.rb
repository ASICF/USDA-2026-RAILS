Rails.application.routes.draw do
  get 'raw_tiff_compare/index'
  root 'pages#index'

  devise_for :users

  # Job Requests
  get '/job_requests', to: 'job_tracker#index', defaults: { format: :json }

  # Graph APIs
  get '/production_status_data', to: 'graph_api#production_status_data'
  get '/milestones', to: 'graph_api#milestones'
  get '/history_activity', to: 'graph_api#history_activity'
  get '/widgets', to: 'graph_api#widgets'

  # Manage
  # -------------------------------------------------------------------
  resources :cameras
  resources :companies
  resources :planes
  resources :users, except: [:destroy]

  # => Unreject Tile
  get 'unreject_tile', to: 'unreject_tile#index', as: :unreject_tile
  get 'unreject_tile/:poly_id', to: 'unreject_tile#show', as: :view_unreject_tile
  post 'unreject_tile/execute', to: 'unreject_tile#execute', as: :execute_unreject_tile

  # MailGroups 
  get 'mail_groups', to: 'mailgroups#index', as: :mailgroups
  post 'mail_groups', to: 'mailgroups#update', as: :update_mailgroups

  # => Excel Export
  get '/excel_export', to: 'timeline#excel_export', as: :excel_export
  get '/history_download/:history_id', to: 'timeline#history_download', as: :history_download

  # => Report History
  get '/report_history', to: 'report_history#index', as: :report_history
  post '/report_history', to: 'report_history#show', as: :report_history_show

  # Inputs
  # -------------------------------------------------------------------
  # => Easements
  get '/easements/new', to: 'easements#new', as: :new_easements
  post '/easements/upload', to: 'easements#upload', as: :upload_easements

  # => DOQQ
  get '/doqqs/new', to: 'doqqs#new', as: :new_doqqs
  post '/doqqs/upload', to: 'doqqs#upload', as: :upload_doqqs

  # => Frame Centers
  get '/frame_centers/new', to: 'frame_centers#new', as: :new_frame_centers
  post '/frame_centers/upload', to: 'frame_centers#upload', as: :upload_frame_centers

  # => Photo Index
  get '/photo_index/new', to: 'photo_index#index', as: :new_photo_index
  post '/photo_index/upload', to: 'photo_index#upload', as: :upload_photo_index
  get '/photo_index/:upload_id/download', to: 'photo_index#download_photo_id', as: :download_photo_id

  # => Footprints
  get '/footprints/new', to: 'footprints#new', as: :new_footprints
  post '/footprints/upload', to: 'footprints#upload', as: :upload_footprints

  # => ADS
  get '/ads/new', to: 'ads#new', as: :new_ads
  post '/ads/upload', to: 'ads#upload', as: :upload_ads

  # => Tile Dump
  get '/tile_dump', to: 'tile_dump#index', as: :new_tile_dumps
  post '/tile_dump/upload', to: 'tile_dump#upload', as: :upload_tile_dumps

  # => Rejections
  get '/rejections/new', to: 'rejections#new', as: :new_rejections
  post '/rejections/upload', to: 'rejections#upload', as: :upload_rejections

  # USDA Approve
  get '/usda_approve', to: 'usda_approve#index', as: :usda_approve
  post '/usda_approve', to: 'usda_approve#create'

  # USDA Reject
  get '/usda_reject', to: 'usda_rejected#index', as: :usda_reject
  post '/usda_reject', to: 'usda_rejected#create'

  # ESRI Log Import
  get '/esri_log_import', to: 'esri_logs#import', as: :esri_log_import
  post '/esri_log_import', to: 'esri_logs#import_execute', as: :esri_log_import_execute

  # Reports
  # -------------------------------------------------------------------
  # => Daily Progress Reports
  get 'daily_progress_reports', to: 'daily_progress_reports#index', as: :daily_progress_reports
  post 'daily_progress_reports/render', to: 'daily_progress_reports#show', as: :display_daily_progress_reports

  # => Weekly Progress Reports
  get 'weekly_progress_reports', to: 'weekly_progress_reports#index', as: :weekly_progress_reports
  post 'weekly_progress_reports/generate', to: 'weekly_progress_reports#generate', as: :generate_weekly_progress_reports

  # => Invoice Report
  get 'delivery_report', to: 'delivery_report#index', as: :delivery_report_reports
  post 'delivery_report/query', to: 'delivery_report#query', as: :delivery_report_query
  get 'delivery_report/export', to: 'delivery_report#export', as: :delivery_report_report_export

  # => Invoice Report
  get 'invoice_nestid', to: 'invoice_nestid_report#index', as: :invoice_nestid_reports
  post 'invoice_nestid/query', to: 'invoice_nestid_report#query', as: :invoice_nestid_query
  get 'invoice_nestid/export', to: 'invoice_nestid_report#export', as: :invoice_nestid_report_export

  # => Export Metadata
  get 'vector_metadata', to: 'vector_metadata#index', as: :vector_metadata
  post 'query_vector_metadata', to: 'vector_metadata#query', as: :query_vector_metadata

  # => ESRI Logs
  get '/eaws_usage_report', to: 'eaws_usage#index', as: :eaws_usage
  post '/eaws_usage_report', to: 'eaws_usage#query', as: :eaws_usage_query
  post '/eaws_usage_export', to: 'eaws_usage#export', as: :eaws_usage_export
  get '/eaws_usage_download/:history_id', to: 'eaws_usage#download', as: :eaws_usage_download

  # => Easements left to fly
  get '/easements_to_fly', to: 'easements_to_fly#index', as: :easements_to_fly
  post '/easements_to_fly/generate', to: 'easements_to_fly#generate', as: :generate_easements_to_fly
  get '/easements_to_fly/download/:history_id', to: 'easements_to_fly#download', as: :download_easements_to_fly

  # => Content File Status
  get '/content_file_status', to: 'content_file_status#index', as: :content_file_status
  post '/content_file_status/generate', to: 'content_file_status#generate', as: :generate_content_file_status

  # => Ready to Ship
  get 'ready_to_ship', to: 'ready_to_ship#index', as: :ready_to_ship
  post 'ready_to_ship/query', to: 'ready_to_ship#query', as: :ready_to_ship_query
  get 'ready_to_ship/county/:county_id', to: 'ready_to_ship#show', as: :county_ready_to_ship

  # => Total Delivery by State and Contractor
  get '/total_delivery_by_state_and_contractor', to: 'total_delivery_by_state_and_contractor#index', as: :total_delivery_by_state_and_contractor
  post '/total_delivery_by_state_and_contractor', to: 'total_delivery_by_state_and_contractor#execute', as: :get_total_delivery_by_state_and_contractor

  # => Tile Dump Compare
  get 'tile_dump_compare/index', to: 'tile_dump_compare#index', as: :tile_dump_compare
  post 'tile_dump_compare/execute', to: 'tile_dump_compare#execute', as: :execute_tile_dump_compare

  # => Raw Tiff Compare
  get 'raw_tiff_compare', to: 'raw_tiff_compare#index', as: :raw_tiff_compare
  post 'raw_tiff_compare/execute', to: 'raw_tiff_compare#execute', as: :execute_raw_tiff_compare

  # => Tiles WIP
  # get '/tiles_wip', to: 'tiles_wip#index', as: :tiles_wip

  # => EO Tracker
  get '/eo_tracker', to: 'eo_tracker#index', as: :eo_tracker
  post '/query_eo_tracker', to: 'eo_tracker#query', as: :query_eo_tracker
  post '/eo_tracker/generate', to: 'eo_tracker#generate_shapefile', as: :eo_tracker_generate_shapefile
  get '/eo_tracker/download/:history_id', to: 'eo_tracker#download', as: :download_eo_tracker_footprints

  # => Photo Index Tracker
  get '/photo_index_tracker', to: 'photo_index_tracker#index', as: :photo_index_tracker
  post '/query_photo_index_tracker', to: 'photo_index_tracker#query', as: :query_photo_index_tracker
  post '/photo_index_tracker/generate', to: 'photo_index_tracker#generate_shapefile', as: :photo_index_tracker_generate_shapefile
  get '/photo_index_tracker/download/:history_id', to: 'photo_index_tracker#download', as: :download_photo_index_tracker_footprints

  # => Total Delivery
  get '/total_delivery', to: 'total_delivery#index', as: :total_delivery
  post 'total_delivery/query', to: 'total_delivery#query', as: :total_delivery_query

  # => Total Delivery by State and County
  get '/total_delivery_by_state_and_county', to: 'total_delivery_by_state_and_county#index', as: :total_delivery_by_state_and_county
  get 'total_delivery_by_state_and_county/:state_abv', to: 'total_delivery_by_state_and_county#show', as: :get_total_delivery_by_state_and_county

  # => Sub Billing
  get '/sub_billing', to: 'sub_billing#index', as: :sub_billing

  # => Flying Status Report
  get 'flying_status_reports/index', to: 'flying_status_reports#index', as: :flying_status_reports
  post 'flying_status_reports/show', to: 'flying_status_reports#show', as: :flying_status_report
  get 'flying_status_reports/export', to: 'flying_status_reports#export', as: :flying_status_export

  # Contractor Breakdown by State
  get 'contractor_breakdown_by_state', to: 'contractor_breakdown_by_state#index', as: :contractor_breakdown_by_state
  get 'contractor_breakdown_by_state/render', to: 'contractor_breakdown_by_state#show', as: :contractor_breakdown_by_state_report
  # get 'contractor_breakdown_by_state/export', to: 'contractor_breakdown_by_state#export', as: :contractor_breakdown_by_state_export
  # get 'contractor_breakdown_by_state/external', to: 'contractor_breakdown_by_state#external', as: :contractor_breakdown_by_state_external

  # Flight Crew Report
  get 'flight_crew_report', to: 'flight_crew_report#index', as: :flight_crew_report
  post 'flight_crew_report/query', to: 'flight_crew_report#query', as: :query_flight_crew_report

  # Tile status Report
  get 'tile_status', to: 'tile_status#index', as: :tile_status_report
  post 'tile_status/query', to: 'tile_status#query', as: :query_tile_status_report
  get 'tile_status_render/:poly_id', to: 'tile_status#show', as: :render_tile_status_report

  # => WIP by State
  get 'wip_by_state', to: 'wip_by_state#index', as: :wip_by_state
  post 'wip_by_state/query', to: 'wip_by_state#query', as: :wip_by_state_query
  post 'wip_by_state/state_query', to: 'wip_by_state#state_query', as: :wip_by_state_state_query

  # => Database Integrity Reports
  get 'database_audit', to: 'database_audits#index', as: :database_audit

  # Export
  # -------------------------------------------------------------------

  # => EO Splitter
  get 'eo_splitter', to: 'eo_splitter#index', as: :eo_splitter
  post 'eo_splitter/query', to: 'eo_splitter#query', as: :query_eo_splitter
  post 'eo_splitter/execute', to: 'eo_splitter#execute', as: :execute_eo_splitter

  # => County Status and Cut File
  get 'county_status_and_cut_file', to: 'county_status_and_cut_file#index', as: :county_status_and_cut_files
  get 'county_status_and_cut_file/:state_id', to: 'county_status_and_cut_file#show', as: :county_status_and_cut_file
  post 'county_status_and_cut_file/generate', to: 'county_status_and_cut_file#generate', as: :generate_cut_file

  # => Packing Slip Worksheet
  get 'packing_slip_worksheet', to: 'packing_slip_worksheet#index', as: :packing_slip_worksheets
  get 'packing_slip_worksheets/:psn', to: 'packing_slip_worksheet#show', as: :packing_slip_worksheet
  get 'packing_slip_worksheets/:psn/export.pdf', to: 'packing_slip_worksheet#export', as: :export_packing_slip_worksheet

  # => Frame Center Rejection
  get 'frame_center_rejection', to: 'frame_center_rejection#index', as: :frame_center_rejection
  post 'frame_center_rejection/export', to: 'frame_center_rejection#export', as: :export_frame_center_rejection

  # => Move Tiles to UTM
  get 'final_delivery/move_tiles_to_utm_folder', to: 'move_tiles_to_utm#index', as: :move_tiles_to_utm
  post 'final_delivery/move_tiles_to_utm_folder/execute', to: 'move_tiles_to_utm#execute', as: :execute_move_tiles_to_utm

  # => Move Tiles from UTM
  get 'final_delivery/move_tiles_from_utm_folder', to: 'move_tiles_from_utm#index', as: :move_tiles_from_utm
  post 'final_delivery/move_tiles_from_utm_folder/execute', to: 'move_tiles_from_utm#execute', as: :execute_move_tiles_from_utm

  # => Generate Metadata and Assign PSN
  get 'final_delivery/generate_metadata_and_assign_psn', to: 'final_delivery#index', as: :final_delivery
  post 'final_delivery/generate_metadata_and_assign_psn/validate', to: 'final_delivery#validate', as: :validate_final_delivery
  post 'final_delivery/generate_metadata_and_assign_psn/execute', to: 'final_delivery#execute', as: :execute_final_delivery
  post 'final_delivery/generate_metadata_and_assign_psn/naip', to: 'final_delivery#naip_execute', as: :naip_final_delivery
  get 'final_delivery/generate_metadata_and_assign_psn/naip_query', to: 'final_delivery#naip_query', as: :naip_final_delivery_query

  # => Export Metadata
  get 'export_provisional_vector_metadata', to: 'export_provisional_vector_metadata#index', as: :export_vector_metadata
  post 'query_provisional_export_vector_metadata', to: 'export_provisional_vector_metadata#provisional_query', as: :query_export_vector_metadata
  post 'query_imagery_paths_provisional_export_vector_metadata', to: 'export_provisional_vector_metadata#provisional_imagery_paths', as: :query_imagery_paths_export_vector_metadata
  post 'execute_export_provisional_vector_metadata', to: 'export_provisional_vector_metadata#provisional_execute', as: :execute_export_vector_metadata
  get '/download_provisional_vector_metadata/:id', to: 'export_provisional_vector_metadata#provisional_download', as: :download_provisional_vector_metadata

  get 'export_production_vector_metadata', to: 'export_production_vector_metadata#index', as: :export_production_vector_metadata
  post 'execute_export_production_vector_metadata', to: 'export_production_vector_metadata#production_execute', as: :execute_export_production_vector_metadata
  get '/download_production_vector_metadata/:history_id', to: 'export_production_vector_metadata#production_download', as: :download_production_vector_metadata

  get '/imagery_upload_status', to: 'imagery_upload_status#index', as: :imagery_upload_status
  post '/imagery_upload_status/query', to: 'imagery_upload_status#query', as: :imagery_upload_status_query
  get '/imagery_upload_status/download', to: 'imagery_upload_status#download', as: :imagery_upload_status_download

  get 'easements_with_multiple_coverages', to: 'easements_with_multiple_coverages#index', as: :easements_with_multiple_coverages
  post 'easements_with_multiple_coverages/query', to: 'easements_with_multiple_coverages#query', as: :query_easements_with_multiple_coverages
  post 'easements_with_multiple_coverages/execute', to: 'easements_with_multiple_coverages#execute', as: :execute_easements_with_multiple_coverages

  # # => Export Frame Centers
  # get 'export_frame_centers', to: 'export_frame_centers#index', as: :export_frame_centers
  # get 'export_frame_centers/generate', to: 'export_frame_centers#generate', as: :generate_export_frame_centers
  # get 'export_frame_centers/execute', to: 'export_frame_centers#execute', as: :execute_export_frame_centers

  # Mailbox Tracking Status
  get '/tracker/:token/logo.png', to: 'pages#tracker', as: :mailbox_tracker

  # Timeline
  # -------------------------------------------------------------------
  get '/timeline', to: 'timeline#index', as: :timeline
  get '/timeline/:timeline_id', to: 'timeline#show', as: :show_timeline
  # get '/updated_timeline/:timeline_id', to: 'timeline#updated_show', as: :updated_show_timeline
  post '/download', to: 'timeline#download', as: :download_from_timeline

  # Export
  # -------------------------------------------------------------------
  get 'uploads/:upload_id/download_original', to: 'export#download_upload_original', as: :download_upload_original

  # Invoices
  resources :invoices, except: [:destroy]
  get 'invoices/:id/export', to: 'invoices#export', as: :invoice_export
  post '/invoices/:id/destroy', to: 'invoices#destroy', as: :destroy_invoice

  # Map
  # -------------------------------------------------------------------
  post '/map/:poly_id.geojson', to: 'maps#fetch'
  # get '/map/tile/:poly_id.geojson', to: 'maps#tile'
  # get '/map/footprints/:poly_id.geojson', to: 'maps#footprints'
  # get '/map/ads/:poly_id.geojson', to: 'maps#ads'
  # get '/map/frame_centers/:poly_id.geojson', to: 'maps#frame_centers'
  # get '/map/easement/:poly_id.geojson', to: 'maps#easement'

end
