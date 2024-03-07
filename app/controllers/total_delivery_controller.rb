class TotalDeliveryController < ApplicationController
    authorize_resource :easements

    def index
        @states = State.active_nri_sl.exclude_geom.select(:id, :name).order(:name)
        @months = Tile.flown.shipped.select(:ship_date).order(:ship_date).map{|record| {date: record.ship_date.beginning_of_month, name: record.ship_date.strftime("%B %Y") }}.uniq
        @projects = Rails.application.secrets.active_projects
    
        # Create History Record
        ReportHistory.create(name: "Total Delivery", user: @current_user)
    end

    def query
    
        p strong_params
    
        if strong_params[:state_id].blank?
          return render json: {
            message: "Missing State parameter", 
            pass: false
          }
        elsif strong_params[:project].blank?
          return render json: {
            message: "Missing Project Parameter", 
            pass: false
          }
        elsif strong_params[:date_from].blank? || strong_params[:date_to].blank?
          return render json: {
            message: "Invalid Date From/Date To parameters", 
            pass: false
          }
        else
          
        #   states = nil
    
          # Find the state and return it in an array
          # => if All then return all active states
          if strong_params[:state_id] === "all"
            if strong_params[:project] == "SL"
              states = State.exclude_geom.active_sl.order(:name)
            else
              states = State.exclude_geom.active_naip.order(:name)
            end
          else
            states = State.exclude_geom.where(id: strong_params[:state_id])
          end
    
          result = []
          states.each do |state|
            if strong_params[:project] == "SL"
              result << state.sl_total_delivery(strong_params[:date_from], strong_params[:date_to])
            else
              result << state.naip_total_delivery(strong_params[:date_from], strong_params[:date_to])
            end
          end

        if params[:state_id] == "all"
            @states = State.active.order(:name)
            @label = "All"
        elsif params[:state_id]
            state = State.find(params[:state_id])
            @states = [state]
            @label = state.name
        end
    
          render json: {
            result: result,
            pass: true
          }
    
        end
    
      end

    def execute
        build_execute

        # Create History Record
        ReportHistory.create(name: "Total Delivery", user: @current_user)
    end

    # def show
    # end

    private

    def build_execute
        if params[:state_id].blank?
            flash[:error] = "No State Selected"
            redirect_to total_delivery_path
        elsif params[:date_from].blank? || params[:date_to].blank?
            flash[:error] = "Invalid ship date range"
            redirect_to total_delivery_path
        else
            @process = params[:process]
            if params[:state_id] == "all"
                @states = State.active.order(:name)
                @label = "All"
            elsif params[:state_id]
                state = State.find(params[:state_id])
                @states = [state]
                @label = state.name
            end
        end
    end

    protected

    def strong_params
        params.permit(:project, :state_id, :date_from, :state_id, :date_to)
    end

end
