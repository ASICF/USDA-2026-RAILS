class UsdaApproveController < ApplicationController
  def index
    @psns = PackingSlip.all.order(:name)
  end

  def create

    params[:user] = @current_user
    response = PackingSlip.usda_approve(params)

    p "---------------"
    p response
    p "---------------"

    if response[:pass]
        flash[:success] = "Approved #{response[:count]} Packing Slips"
        redirect_to usda_approve_path
    else
        flash[:error] = response[:errors]
        redirect_to usda_approve_path
    end

  end
end
