class EsriLogsController < ApplicationController
    include ApplicationHelper
    before_action :manager_check, only: [:import, :import_execute]

    def import
        redirect_to root_path if !Rails.application.secrets.active_projects.include? "NAIP"
    end

    def import_execute

        p params

        if params[:input_directory].blank?
            return render json: {
                state: false,
                message: "No Input Directory Supplied"
            }
        elsif !params[:input_directory].include? Rails.application.secrets.esri_log_required
            return render json: {
                state: false,
                message: "Input Directory must be a nested folder of #{Rails.application.secrets.esri_log_required}"
            }
        end

        WebLogUpload.import params[:input_directory], current_user

        render json: {
            state: true,
            message: "Form Data and Shapefile has been uploaded to the server and validated. Import process has been added to Job Queue. You will receive a message when it is completed."
        }

    end

end
