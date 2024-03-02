class TilesWipController < ApplicationController
    authorize_resource :tiles

    def index

        if params[:date_from].present? || params[:date_to].present?
        end

        if params[:date_from].blank?
            params[:date_from] = Tile.select(:flight_date).order(:flight_date).first.flight_date
        end

        if params[:date_to].blank? && params[:date_from].present?
            params[:date_to] = Date.today if params[:date_from] < Date.today
        end

        @months = Tile.flown.select(:flight_date).map{|record| record.flight_date.month}.uniq

        if params[:state_id] && params[:state_id] != "all" && State.find(params[:state_id]).present?
            @state = State.find(params[:state_id])
        elsif
            params[:state_id] = "all"
            @states = State.includes(:tiles).active
        end

        # Create History Record
        ReportHistory.create(name: "Tiles WIP", user: @current_user)

    end

end
