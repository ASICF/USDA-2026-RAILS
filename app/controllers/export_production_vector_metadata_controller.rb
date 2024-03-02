class ExportProductionVectorMetadataController < ApplicationController

    def index
        redirect_to root_path if !Rails.application.secrets.active_projects.include? "NAIP"

        if @current_user.admin? || @current_user.manager?
      
            @active = [{
                project: "NAIP",
                state: "New Jersey",
                state_id: 11,
                min_flight_date: VectorMetadatum.naip.order(:flight_date).first.flight_date,
                max_flight_date: VectorMetadatum.naip.order(:flight_date).last.flight_date,
                count: Doqq.count
            }, {
                project: "SL",
                state: "Rhode Island",
                state_id: 5,
                min_flight_date: VectorMetadatum.sl.where(state_id: 5).order(:flight_date).first.flight_date,
                max_flight_date: VectorMetadatum.sl.where(state_id: 5).order(:flight_date).last.flight_date,
                count: State.find_by(abv: "NJ").tiles.count
            }]

        else
            redirect_to root_path
        end

    end

    def production_execute
        p "production_execute"
        if @current_user.admin? || @current_user.manager?
            response = VectorMetadatum.production_export params[:project], params[:state_id], current_user

            p "---------------"
            p response
            p "---------------"

            render json: {
                state: response[:pass],
                message: response[:message],
                history_id: response[:history_id],
            }

        end
    end


    def production_download

        if params[:history_id].blank?
            render json: {
                pass: false,
                message: "No ID Found"
            }
        end

        history = History.find_by(id: params[:history_id])

        if history
            if File.exist? history.url
                send_file(
                    history.url,
                    filename: File.basename(history.url),
                    type: "application/zip"
                )
            else
            end
        end

    end

end
