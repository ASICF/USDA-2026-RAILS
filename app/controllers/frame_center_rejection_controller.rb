class FrameCenterRejectionController < ApplicationController
  def index
    @states = State.where(id: FrameCenter.rejected.pluck(:state_id).uniq).order(:name)
  end

  def export
    p params

    if params[:state].blank? || params[:flight_date].blank?
      flash[:error] = "Invalid Parameters"
      redirect_to frame_center_rejection_path
    end

    params[:user] = @current_user
    # response = FrameCenter.generate_rejected_shapefile(params)
    response = FrameCenter.frame_centers_with_sun_angle_errors params

    p "---------------"
    p response
    p "---------------"

    if response[:pass]
        send_file(
            response[:file],
            filename: response[:file_name],
            type: "text/plain"
        )
    else
        flash[:error] = response[:errors]
        redirect_to frame_center_rejection_path
    end

  end
end
