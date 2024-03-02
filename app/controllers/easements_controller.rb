class EasementsController < ApplicationController
    authorize_resource :easements

    def new
        redirect_to root_path if !@current_user.admin?
    end

    def upload

        if @current_user.admin?
            if params[:files].blank?
                redirect_to new_easements_path, notice: "No Shapefile Found"
            elsif params[:project].blank?
                redirect_to new_easements_path, notice: "No Project specified"
            else
                response = Easement.prepare_import params, current_user

                p "---------------"
                p response
                p "---------------"

                flash[response[:pass] ? :success : :error] = response[:message]
                redirect_to new_easements_path

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
