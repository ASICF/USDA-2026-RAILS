class FootprintsController < ApplicationController
    authorize_resource :footprints

    def new
        @companies = Company.all.select(:id, :alias, :name).order(:alias)
        @cameras = [{id: "auto", label: "ASI Auto Detect", company_id: 1}] + Camera.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name} | #{c.serial_number}", company_id: c.company_id, naip: c.naip, sl: c.sl} }
        @planes = Plane.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name}", company_id: c.company_id, naip: c.naip, sl: c.sl} }
        @states = State.active_naip.order(:name).map { |state| {id: state.id, name: state.name } }
        @projects = ["NRI/SL"]
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
        elsif footprint_params[:camera_id].blank?
            render json: {
                state: false,
                message: "No Camera Selected"
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
        params.require(:footprints).permit(:project, :flown_by_id, :camera_id, files: [])
    end
end
