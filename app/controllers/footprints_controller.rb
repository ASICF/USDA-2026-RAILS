class FootprintsController < ApplicationController
    authorize_resource :footprints

    def new
        @companies = Company.all.select(:id, :alias, :name).order(:alias)
        @cameras = Camera.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name} | #{c.serial_number}", company_id: c.company_id, naip: c.naip, sl: c.sl} }
        @planes = Plane.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name}", company_id: c.company_id, naip: c.naip, sl: c.sl} }
        @states = State.active_naip.order(:name).map { |state| {id: state.id, name: state.name } }
        @projects = Rails.application.secrets.active_projects
    end

    def upload

        # pp params
        p footprint_params

        if footprint_params[:files].blank?
            render json: {
                state: false,
                message: "No Shapefile Found"
            }
        elsif footprint_params[:project].blank?
            render json: {
                state: false,
                message: "No Project Specified"
            }
        elsif footprint_params[:project] == "NAIP" && footprint_params[:state_id].blank?
            render json: {
                state: false,
                message: "NAIP Projects require selected state."
            }
        else

            response = Footprint.prepare_import footprint_params, current_user

            p "---------------"
            p response
            p "---------------"

            render json: {
                state: response[:pass],
                message: response[:message]
            }
        end

    end

    def footprint_params
        params.require(:footprints).permit(:project, :flown_by_id, :flight_date, :state_id, :plane_id, :camera_id, :pilot_name, :sensor_operator, :last_file, files: [])
    end
end
