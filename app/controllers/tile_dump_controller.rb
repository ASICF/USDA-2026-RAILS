class TileDumpController < ApplicationController
  def index
    # @states = State.active_sl.select(:id, :name)
    # @projects = Rails.application.secrets.active_projects
    @sl_states = State.active_sl.exclude_geom.select(:id, :name)
    @nri_states = State.active_nri.exclude_geom.select(:id, :name)
    @projects = ["SL", "NRI"]

    # Create History Record
    ReportHistory.create(name: "Tile Dump Compare", user: @current_user)
  end

  def upload

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
    elsif params[:state_id].blank?
        render json: {
            state: false,
            message: "No State specified"
        }
    else

      # Check if the file is not blank
      if params[:input_directory].blank?
        flash[:error] = "No File Found"
        redirect_to new_tile_dumps_path
      else

        params[:user] = @current_user
        Tile.delay.set_dump_date(params)

        render json: {
          state: true,
          message: "Tile Dump request has been submitted to the server and has been added to Job Queue. You will receive a message when it is completed."
        }

      end

    end
  end
end
