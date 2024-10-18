class EoSplitterController < ApplicationController
  def index
    # @uploads = Upload.where(upload_type: "FrameCenter").pluck(:id)
    @projects = ["NRI/SL"]
  end

  def query
    p params

    results = []

    date_flown_from = Time.parse(params[:flight_date]).utc.beginning_of_day
    date_flown_to = Time.parse(params[:flight_date]).utc.end_of_day

    # find any frame centers with the same flight date
    # FrameCenter.where(flight_date: params[:flight_date], project: params[:project]).
    Upload.includes(:frame_centers).where(upload_type: "FrameCenter", frame_centers: {flight_date: date_flown_from..date_flown_to, project: "NRI/SL"}).order(:created_at).each do |upload|
      p upload.id

      results << {
        id: upload.id,
        project: upload.frame_centers.first.project,
        flight_date: upload.frame_centers.first.flight_date.strftime("%m/%d/%Y"),
        upload_date: upload.created_at.strftime("%m/%d/%Y"),
        fc_count: upload.frame_centers.count,
        states: upload.frame_centers.pluck(:state_abv).uniq.join(", "),
        utm: upload.frame_centers.pluck(:utm_zone).uniq.join(", ")
      }

    end

    if results.count > 0
      render json: {
        results: results,
        pass: true
      }
    else
      render json: {
        message: "No Frame Center Uploads found with Flight date and Project", 
        pass: false
      }
    end

    # date_flown_from = Time.parse("2024-10-12").utc.beginning_of_day
    # date_flown_to = Time.parse("2024-10-12").utc.end_of_day
    # Upload.includes(:frame_centers).where(upload_type: "FrameCenter", frame_centers: {flight_date: date_flown_from..date_flown_to, project: "NRI/SL"})
  end

  def execute
    p params

    if params[:upload_id]
      # get the upload
      upload = Upload.find_by(id: params[:upload_id], upload_type: "FrameCenter")

      if upload
        render json: FrameCenter.rerun_eo_splitter(upload)
      else
        render json: {
          message: "Selected Upload d", 
          pass: false
        }
      end
    else
      render json: {
        message: "No Upload selected", 
        pass: false
      }
    end
  end
end
