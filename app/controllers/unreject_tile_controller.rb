class UnrejectTileController < ApplicationController
  include ApplicationHelper
  before_action :manager_check 
  authorize_resource :tiles

  def index
    # @rejected_tiles = Tile.not_dumped.has_rejections.order(:poly_id).pluck(:poly_id).uniq
    @rejected_tiles = []
    Tile.not_dumped.has_rejections.order(:poly_id).each do |tile|
      @rejected_tiles << {
        poly_id: tile.poly_id,
        num_of_rejected_tiles: tile.rejected_tiles.count
      }
    end
  end

  def show
    @tile = Tile.find_by(poly_id: params[:poly_id])
  end

  def execute
    p params

    result = {
      pass: false,
      message: nil
    }

    rt = RejectedTile.find_by(id: params["rejected_tile_id"])

    if params["poly_id"].blank? || params["poly_id"].blank? || params["poly_id"].blank?
      flash[:error] = "No Scope provided"
    elsif rt.nil?
      flash[:error] = "No Rejected Tile Found"
    else
      result = rt.unreject @current_user
      flash[result[:status] ? :success : :error] = result[:message]
    end

    render json: result

  end
end
