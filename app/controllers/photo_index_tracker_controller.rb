class PhotoIndexTrackerController < ApplicationController
  def index

    @uploads = []

    Upload.includes(:footprints).where(upload_type: "Footprint", footprints: {flight_date_time: nil, has_pi: false, associated: true}).order(id: :ASC).each do |upload|

      first_footprint = upload.footprints.first

      @uploads << {
        upload_id: upload.id,
        history_id: upload.history.id,
        state_name: upload.footprints.pluck(:state_name).uniq.join(", "),
        project: first_footprint.project,
        upload_created_at: upload.created_at,
        flown_by: first_footprint.flown_by_alias,
        camera: first_footprint.camera_name,
        time_offset: (DateTime.now - first_footprint.flight_date).to_i,
        plane: first_footprint.plane_name,
        flight_date: first_footprint.flight_date,
        total_footprints: upload.footprints.count,
        footprints_with_pis: upload.footprints.where(associated: true, has_pi: true).where.not(flight_date_time: nil).count,
        footprints_that_need_pis: upload.footprints.where(associated: true, has_pi: false, flight_date_time: nil).count
      }
      
      # Create History Record
      ReportHistory.create(name: "Photo Index Tracker", user: @current_user)

    end

    @uploads

  end

  def query

    p params

    poly_ids = []
    strip_frames = []

    # Get the upload
    upload = Upload.includes(footprints: [:tiles]).find_by(id: params["upload_id"])

    # iterate the footprints and find tiles that meet the requirements
    upload.footprints.includes(:tiles).where(associated: true, has_pi: false, flight_date_time: nil).each do |fp|
      # fp.tiles.flown.not_at_started.where("tiles.flight_date < ?", Time.now - 10.days).each do |tile|
      fp.tiles.flown.each do |tile|
        poly_ids |= [{poly_id: tile.poly_id, project: tile.project}]
      end
      strip_frames |= [fp.strip_frame]
    end

    render json: {
      poly_ids: poly_ids,
      strip_frames: strip_frames
    }
  end
end
