class FootprintTrackerController < ApplicationController
  def index

    @uploads = []

    Upload.includes(:photo_indices).where(upload_type: "PhotoIndex", photo_indices: {has_footprint: false}).order(id: :ASC).each do |upload|

      first_photo_index = upload.photo_indices.first

      @uploads << {
        upload_id: upload.id,
        history_id: upload.history.id,
        state_name: upload.photo_indices.pluck(:state_name).uniq.compact.join(", "),
        project: first_photo_index.project,
        upload_created_at: upload.created_at,
        flown_by: first_photo_index.flown_by_alias,
        camera: first_photo_index.camera_name,
        time_offset: (DateTime.now - first_photo_index.flight_date).to_i,
        plane: first_photo_index.plane_name,
        flight_date: first_photo_index.flight_date,
        total_photo_indices: upload.photo_indices.count,
        pis_with_footprints: upload.photo_indices.where(has_footprint: true).count,
        pis_that_need_footprints: upload.photo_indices.where(has_footprint: false).count
      }

      # Create History Record
      ReportHistory.create(name: "Footprint Tracker", user: @current_user)

    end

    @uploads
  end
end
