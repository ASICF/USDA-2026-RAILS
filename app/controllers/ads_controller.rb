class AdsController < ApplicationController
    authorize_resource :airborne_digital_sensors

    def new
        @companies = Company.all.select(:id, :name).order(:name)
        @cameras = Camera.all.order(:name).map { |c| {id: c.id, label: "#{c.company.alias} | #{c.name} | #{c.serial_number}", company_id: c.company_id} }
        @states = State.active.order(:name).map { |state| {id: state.id, name: state.name } }
    end

    def upload

        if params[:files].blank?
            redirect_to new_ads_path, notice: "No Shapefile Found"
        elsif params[:at].blank?
            redirect_to new_ads_path, notice: "No AT Status Found"
        elsif params[:flight_date].blank?
            redirect_to new_ads_path, notice: "No Flgiht Date Found"
        else
            params[:user] = @current_user
            response = AirborneDigitalSensor.import(params)

            p "---------------"
            p response
            p "---------------"

            status = "AT Started"
            if params[:at] == "done"
                status = "AT Done"
            end

            if response[:pass]
                flash[:success] = "Successfully uploaded #{response[:count]} ADS boundaries and set #{response[:tiles_updated]} Tiles as #{status}!"
                redirect_to new_ads_path
            else
                flash[:error] = response[:errors]
                redirect_to new_ads_path
            end
        end

    end

end
