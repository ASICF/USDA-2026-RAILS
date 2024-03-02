class PhotoIndexController < ApplicationController
  def index
    @companies = Company.all.select(:id, :name, :alias).order(:name)
    @cameras = Camera.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name} | #{c.serial_number}", company_id: c.company_id} }
    @projects = Rails.application.secrets.active_projects
  end

  def upload
    p params
    p strong_params

    if strong_params[:project].blank? || strong_params[:file].blank? || strong_params[:flown_by_id].blank? || strong_params[:camera_id].blank?
        # redirect_to new_frame_centers_path, error: "No Shapefile Found"

        render json: {
            state: false,
            message: "Missing required parameter. Double check form and resubmit."
        }
    else
        # response = FrameCenter.import(strong_params, @current_user)
        response = PhotoIndex.prepare_import strong_params, current_user

        p "---------------"
        p response
        p "---------------"

        render json: {
            state: response[:pass],
            message: response[:message]
        }

    end
  end

  def download_photo_id

    if params[:upload_id].blank?
      flash[:error] = "Unable to process download request"
      redirect_to timeline_path
    else

      # get the upload
      upload = Upload.find(params[:upload_id])

      # return the photo id file
      txt = PhotoIndex.retrieve_photo_id upload

      if txt
        send_file(
          txt,
          type: "text/plain"
        )
      end

    end

  end

  def strong_params
    params.require(:photo_index).permit(:project, :flown_by_id, :camera_id, :file)
  end

end
