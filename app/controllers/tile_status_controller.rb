class TileStatusController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
      # Create History Record
      ReportHistory.create(name: "Tile Status", user: @current_user)
  end

  def query
    # query tiles by poly ids
    if params[:poly_id]
      render json: {
        state: true,
        result: Tile.select(:poly_id, :project, :county_name, :state_name, :flight_date, :at_done_date, :ortho_proc_date, :ship_date, :invoiced_date, :usda_accepted_date).where("LOWER(poly_id) ILIKE ?", "%#{params[:poly_id].downcase}%").order(:poly_id).limit(50)
      }
    else
      render json: {
        state: false,
        message: "No PolyID passed with query"
        
      }
    end
  end

  def show
    @tile = Tile.exclude_geom.find_by(poly_id: params[:poly_id].upcase)

    if @tile.nil?
      redirect_to tile_status_report_path, notice: "Invalid PolyID"
      
    else

      # query out the associations
      @footprints = @tile.footprints.exclude_geom
      p @footprints.pluck(:id)
      @frame_centers = FrameCenter.where(footprint_id: @footprints.pluck(:id))
      @photo_index = PhotoIndex.where(footprint_id: @footprints.pluck(:id))
      @rejected_tiles = @tile.rejected_tiles.count
      # @production_rate = @tile.production_rate.nil? ? nil : @tile.production_rate
      # @flight_rate = @tile.flight_rate.nil? ? nil : @tile.flight_rate
     
    end
  end
end
