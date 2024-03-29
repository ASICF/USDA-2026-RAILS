class FinalDeliveryController < ApplicationController
    authorize_resource :tiles

    def index
        # @projects = Rails.application.secrets.active_projects
        # @states = State.active_sl.select(:id, :name)

        @sl_states = State.active_sl.exclude_geom.select(:id, :name)
        @nri_states = State.active_nri.exclude_geom.select(:id, :name)
        @projects = ["SL", "NRI"]

        if params[:psn_id]
            @psn = PackingSlip.find(params[:psn_id])
        end
    end

    def validate

        p params

        if params[:input_directory].blank?
            render json: {
                state: false,
                message: "No Input Directory Specified"
            }
        elsif params[:state_id].blank?
            render json: {
                state: false,
                message: "No State specified"
            }
        elsif params[:project].blank?
            render json: {
                state: false,
                message: "No Project specified"
            }
        else

            response = FinalDelivery.nrisl_validate_files params, current_user

            p "asdfasdfasdfasdf"
            pp response

            render json: response

            # if response[:pass]
            #     # @count = response[:count]
            #     # @result = response[:result]
            #     # @input_directory = params[:input_directory]
            #     # @content_file = response[:content_file]
            #     # @batch_process_id = response[:batch_process_id]

            #     render json: response

            # else
            #     # flash[:error] = response[:errors]
            #     # redirect_to final_delivery_path

            #     render json: {
            #         state: response[:pass],
            #         message: response[:message]
            #     }
            # end
        end

    end

    def execute
        p "+"
        pp final_delivery_params
        p ![true, false].include?(final_delivery_params[:preproduction])
        p "+"

        # asdfasdf

        if final_delivery_params[:input_directory].blank?
            return render json: {
                state: false,
                message: "Unable to process request due to missing input directory"
            }
        elsif final_delivery_params[:project].blank?
            return render json: {
                state: false,
                message: "Missing Project"
            }
        elsif final_delivery_params[:delivery_type].blank?
            return render json: {
                state: false,
                message: "Missing Delivery Type"
            }
        elsif final_delivery_params[:delivery_type] == "Production" && final_delivery_params[:packing_slip_name].blank?
            return render json: {
                state: false,
                message: "No Packing Slip found"
            }
        elsif final_delivery_params[:count].blank?
            return render json: {
                state: false,
                message: "Missing previous Tiff count from Validation Form"
            }
        elsif final_delivery_params[:coverage].blank?
            return render json: {
                state: false,
                message: "Missing Coverage Type"
            }
        elsif final_delivery_params[:counties].blank? && final_delivery_params[:counties].length > 0
            return render json: {
                state: false,
                message: "No Counties selected"
            }
        elsif final_delivery_params[:state_id].blank?
            return render json: {
                state: false,
                message: "No State Parameter passed from first form"
            }
        else

            response = FinalDelivery.nrisl_prepare final_delivery_params, current_user
    
            return render json: {
                state: response[:pass],
                message: response[:message]
            }

        end

    end

    def naip_query
        return render json: {
            state: true,
            results: Doqq.select(:filename).flown.at_done.not_shipped
        }
    end

    def naip_execute
        p naip_params


        if final_delivery_params[:input_directory].blank?
            return render json: {
                state: false,
                message: "Missing Input Directory"
            }
        elsif final_delivery_params[:ship_date].blank?
            return render json: {
                state: false,
                message: "Missing Ship Date parameter"
            }
        elsif final_delivery_params[:packing_slip_name].blank?
            return render json: {
                state: false,
                message: "No Packing Slip found"
            }
        else

            response = FinalDelivery.naip_prepare naip_params, current_user

            p response

            return render json: {
                state: response[:pass],
                message: response[:message]
            }

        end

    end
    
    protected

    def final_delivery_params
        params.permit(:input_directory, :project, :count, :ship_date, :delivery_type, :coverage, :packing_slip_name, :state_id, counties: [])
    end

    # def naip_params
    #     params.permit(:input_directory, :ship_date, :packing_slip_name)
    # end
end
