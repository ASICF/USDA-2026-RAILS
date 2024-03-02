class RejectionsController < ApplicationController
    authorize_resource :rejections

    def new
        redirect_to root_path if @current_user.production?
    end

    def upload
        redirect_to root_path if @current_user.production?
        p rejection_params

        if rejection_params[:file].blank?
            render json: {
                state: false,
                message: "Missing text file"
            }
        elsif rejection_params[:flight_date].blank?
            render json: {
                state: false,
                message: "Missing Flight Date"
            }
        # elsif rejection_params[:reject_date].blank?
        #     render json: {
        #         state: false,
        #         message: "Missing Reject Date"
        #     } 
        else

            response = Rejection.import rejection_params, @current_user

            p "---------------"
            p response
            p "---------------"

            if response[:pass]
                render json: {
                    state: true,
                    message: response[:message]
                }
            else
                render json: {
                    state: false,
                    message: response[:errors].kind_of?(Array) ? response[:errors].join(", ") : response[:errors]
                }
            end
        end

    end

    private

    def rejection_params
        p params
        params.require(:rejection).permit(:flight_date, :reject_date, :file)
    end

end
