class RawTiffCompareController < ApplicationController

  def index
    @projects = ["NRI/SL"]
  end

  def execute
    pp params


    if params[:input_directory].blank?
      render json: {
          state: false,
          message: "No Input Directory Specified"
      }
    elsif params[:project].blank?
        render json: {
            state: false,
            message: "No Project specified"
        }
    elsif params[:flight_date].blank?
        render json: {
            state: false,
            message: "No Flight Date specified"
        }
    else

      response = Footprint.raw_tiff_compare params, current_user

      render json: response

    end
  end
end
