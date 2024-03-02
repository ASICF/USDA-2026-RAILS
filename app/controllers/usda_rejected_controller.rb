class UsdaRejectedController < ApplicationController
  def index
  end

  def create
    p params
  
    if params[:file].nil?
        flash[:error] = "No File was Uploaded!"
        redirect_to usda_reject_path
    else
        params[:user] = @current_user
        response = Tile.usda_rejection(params)

        p "---------------"
        p response
        p "---------------"

        if response[:pass]
            flash[:success] = "Successfully add USDA Rejected Date to #{response[:count]} Tiles!"
            redirect_to usda_reject_path
        else
            flash[:error] = response[:errors]
            redirect_to usda_reject_path
        end
    end
  end
end
