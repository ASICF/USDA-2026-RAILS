class PhotoIndexController < ApplicationController
  def index
    @companies = Company.all.select(:id, :name, :alias).order(:name)
    @cameras = [{id: "auto", label: "ASI Auto Detect", company_id: 1}] + Camera.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name} | #{c.serial_number}", company_id: c.company_id} }
    @projects = ["NRI/SL"]
  end

  def upload
    p params
    p strong_params

    # if strong_params[:project].blank? || strong_params[:file].blank? || strong_params[:flown_by_id].blank? || strong_params[:camera_id].blank? || strong_params[:flight_date].blank?


    if strong_params[:project].blank?
      render json: {
          state: false,
          message: "No Project Specified"
      }
    elsif strong_params[:file].blank?
        render json: {
            state: false,
            message: "No State specified"
        }
    elsif strong_params[:flown_by_id].blank?
        render json: {
            state: false,
            message: "No Company specified"
        }
    elsif strong_params[:camera_id].blank?
        render json: {
            state: false,
            message: "No Company specified"
        }
    # elsif strong_params[:flight_date].blank?
    #     render json: {
    #         state: false,
    #         message: "No Flight Date specified"
    #     }
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
