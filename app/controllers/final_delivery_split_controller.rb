class FinalDeliverySplitController < ApplicationController
  authorize_resource :tiles

  def index
    @packing_slips = PackingSlip.all.order("created_at DESC")
  end

  def execute
    p params

    if params[:input_directory].blank?
      render json: {
          state: false,
          message: "No Final Delivery Directory specified"
      }
    elsif params[:packing_slip].blank?
        render json: {
            state: false,
            message: "No Packing Slip specified"
        }
    else

      packing_slip = PackingSlip.find_by(id: params[:packing_slip])

      if packing_slip.present?

        response = FinalDeliverySplits.preprocessing params[:input_directory], packing_slip
        pp response

        render json: response

      else
        render json: {
            state: false,
            message: "Selected Packing Slip does not exist"
        }
      end

    end
  end
end
