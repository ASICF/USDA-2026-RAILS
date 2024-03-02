class ContentFileStatusController < ApplicationController
    authorize_resource :tiles

    def index
        # Create History Record
        ReportHistory.create(name: "Content File Status", user: @current_user)
    end

    def generate

        if params[:file].blank?
            flash[:error] = "No Content File Uploaded"
            redirect_to content_file_status_path
        else
            response = Tile.generate_tile_status_from_content_file(params)

            p "---------------"
            p response
            p "---------------"

            if response[:pass]
                @result = response[:result]
            else
                flash[:error] = response[:errors]
                redirect_to content_file_status_path
            end
        end

    end

end