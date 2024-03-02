class MoveTilesToUtmController < ApplicationController
    authorize_resource :tiles

    def index
    end

    def execute

        if params[:input_directory].blank?
            flash[:error] = "No Input Directory Found"
            redirect_to move_tiles_to_utm_path
        end

        response = Task.move_tiffs_to_utm params

        p response

        if response[:pass]
            flash[:success] = "Moved #{response[:count]} Tiffs to UTM Folders"
            redirect_to move_tiles_to_utm_path
        else
            flash[:error] = response[:errors]
            redirect_to move_tiles_to_utm_path
        end

    end

end