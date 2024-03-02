class TileDumpCompareController < ApplicationController
  def index
    @projects = Rails.application.secrets.active_projects
    @states = State.exclude_geom.select(:id, :name)
  end

  def execute
    p tile_dump_params

    if tile_dump_params[:project].blank? || tile_dump_params[:file].blank? || tile_dump_params[:state_id].blank?
      # redirect_to new_frame_centers_path, error: "No Shapefile Found"

      render json: {
          state: false,
          message: "Missing required parameter. Double check form and resubmit."
      }
    else

        response = Tile.compare_tile_dump tile_dump_params

        # Create History Record
        ReportHistory.create(name: "Tile Dump Compare", user: @current_user)

        # p "---------------"
        # p response
        # p "---------------"

        render json: response

    end

  end

  private

  def tile_dump_params
    params.require(:tile_dump_compare).permit(:project, :state_id, :file)
  end

end
