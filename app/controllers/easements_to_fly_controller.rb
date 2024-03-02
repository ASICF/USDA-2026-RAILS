class EasementsToFlyController < ApplicationController
    authorize_resource :easements

    def index
        @states = State.includes(:easements).active

        @remaining_sl = Easement.remaining_to_fly if Rails.application.secrets.active_projects.include? "SL"
        @remaining_naip = Doqq.remaining_to_fly if Rails.application.secrets.active_projects.include? "NAIP"

        # Create History Record
        ReportHistory.create(name: "Easements to Fly", user: @current_user)
    end

    def generate

        p params

        states = params[:states] || []

        if states.count == 0
            return render json: {
                state: false,
                message: "No States Selected!"
            }
        elsif params[:project].blank?
            return render json: {
                state: false,
                message: "No Project Detected"
            }
        else
            params[:user] = @current_user

            if params[:project] == "SL"
                response = Easement.generate_shapefile(params)
            else
                response = Doqq.generate_shapefile(params)
            end

            p "---------------"
            p response
            p "---------------"

            return render json: response
        end

    end

    def download

        history = History.find(params[:history_id])

        if history.nil?
            raise exception
        end

        send_file(
            history.url,
            filename: File.basename(history.url),
            type: "application/zip"
        )

    end

end
