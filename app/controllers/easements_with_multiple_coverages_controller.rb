class EasementsWithMultipleCoveragesController < ApplicationController
  # get the tiles marked as covered
  def index
    records, rejected = build

    @records = records
    @rejected = rejected

    # Create History Record
    ReportHistory.create(name: "Easements with Multiple Coverages", user: @current_user)
  end

  # query out footprints that cover the easement
  def query
    p params

    if params[:id].blank?
      render json: {
        state: false,
        message: "Selected Tile ID not found in request"
      }
    else
      # Get the tile
      tile = Tile.find(params[:id])

      # Check if the tile is marked as covered or not
      if !tile.covered
        render json: {
          state: false,
          message: "Tile is not marked as covered in database"
        }
      else
        response = tile.find_covered

        render json: {
          state: response[:pass],
          message: response[:message],
          result: response[:result]
        }
      end
    end
  end

  def execute
    p params

    if params[:tile_id].blank? || params[:upload_id].blank?
      render json: {
        state: false,
        message: "Missing required parameters"
      }
    else
      # Get the tile and upload records
      tile = Tile.find_by(id: params[:tile_id], covered: true)
      upload = Upload.find(params[:upload_id])

      if tile.nil?
        return render json: {
          state: false,
          message: "Tile does not exist"
        }
      end

      if upload.nil?
        return render json: {
          state: false,
          message: "Upload does not exist"
        }
      end

      if tile && upload

        response = Tile.update_footprint_association tile, upload, current_user

        records, rejected = build

        render json: {
          state: true,
          result: records,
          rejected: rejected
        }

      end

    end
  end

  private

  def build
    records = Tile.flown.covered.not_ortho_processed.select(:id, :poly_id, :state_name, :county_name, :flight_date, :flown_by_alias).order(:flight_date)
    rejected = []
    Tile.not_flown.covered.select(:id, :poly_id, :state_name, :county_name).order(:flight_date).each do |tile|
      rejected << {
        id: tile.id,
        poly_id: tile.poly_id,
        state_name: tile.state_name,
        county_name: tile.county_name,
        rejected_date: tile.rejected_tiles.order(rejected_date: :DESC).first.flight_date
      }
    end

    return records, rejected
  end
end
