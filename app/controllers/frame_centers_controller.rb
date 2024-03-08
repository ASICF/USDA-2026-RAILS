class FrameCentersController < ApplicationController
    authorize_resource :frame_centers

    def new
        @companies = Company.all.select(:id, :name, :alias).order(:name)
        @cameras = Camera.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name} | #{c.serial_number}", company_id: c.company_id} }
        @states = State.active_naip.order(:name).map { |state| {id: state.id, name: state.name } }
        @projects = ["NRI/SL"]
        @sl_split_path = Rails.application.secrets.sl_eo_splitter_p_path
        @nri_split_path = Rails.application.secrets.nri_eo_splitter_p_path
    end

    def upload
        # p params
        # p frame_center_params

        if frame_center_params[:project].blank? || frame_center_params[:file].blank? || frame_center_params[:flight_date].blank? || frame_center_params[:flown_by_id].blank? || frame_center_params[:camera_id].blank?
            # redirect_to new_frame_centers_path, error: "No Shapefile Found"

            render json: {
                state: false,
                message: "Missing required parameter. Double check form and resubmit."
            }
        elsif frame_center_params[:project] == "NAIP" && frame_center_params[:state_id].blank?
            render json: {
                state: false,
                message: "NAIP Projects require selected state."
            }
        else

            # response = FrameCenter.import(frame_center_params, @current_user)
            response = FrameCenter.prepare_import frame_center_params, current_user

            p "---------------"
            p response
            p "---------------"

            render json: {
                state: response[:pass],
                message: response[:message]
            }

        end

    end

    def frame_center_params
        params.require(:frame_centers).permit(:project, :flown_by_id, :camera_id, :flight_date, :state_id, :file, :output_path)
    end

end

