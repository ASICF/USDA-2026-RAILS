class CountyStatusAndCutFileController < ApplicationController
    authorize_resource :easements

    def index
        @states = State.active
    end

    def show
        @state = State.includes(counties: [:easements]).find(params[:state_id])
    end

    def generate

        counties = params[:counties] || []

        if counties.count == 0
            flash[:error] = "No Counties selected!"
            redirect_to county_status_and_cut_file_path(state_id: params[:state_id])
        else
            params[:user] = @current_user
            response = Tile.generate_cutfile(params)

            p "---------------"
            p response
            p "---------------"

            if response[:pass]
                send_file(
                    response[:file],
                    filename: response[:file_name],
                    type: "text/plain"
                )
            else
                flash[:error] = response[:errors]
                redirect_to county_status_and_cut_file_path params[:state_id]
            end
        end

    end

end
