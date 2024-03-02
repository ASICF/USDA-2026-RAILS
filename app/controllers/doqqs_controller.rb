class DoqqsController < ApplicationController
    authorize_resource :doqqs

    def new
        redirect_to root_path if !Rails.application.secrets.active_projects.include? "NAIP"
        redirect_to root_path if !@current_user.admin?
        @states = State.where(abv: Rails.application.secrets.active_naip_states).select(:id, :name)
    end

    def upload

        p params[:state_id]

        if current_user.admin?
            if params[:files].blank?
                render json: {
                    state: false,
                    message: "No Shapefile Found"
                }
            else
                response = Doqq.prepare_import params, current_user

                p "---------------"
                p response
                p "---------------"

                render json: {
                    state: response[:pass],
                    message: response[:message]
                }

                # flash[response[:pass] ? :success : :error] = response[:message]
                # redirect_to new_easements_path

                # response = Easement.import(params)

                # if response[:pass]
                #     flash[:success] = "Successfully uploaded #{response[:count]} Buffered Easements!"
                #     redirect_to new_easements_path
                # else
                #     flash[:error] = response[:errors]
                #     redirect_to new_easements_path
                # end
            end
        end

    end
end
