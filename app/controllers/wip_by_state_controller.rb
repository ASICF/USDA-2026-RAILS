class WipByStateController < ApplicationController
  include WipByStateHelper

  def index
    @states = State.select(:id, :name).order(:name)

    calc_wip_by_state_months

    @projects = Rails.application.secrets.active_projects

    # Create History Record
    ReportHistory.create(name: "WIP by State", user: @current_user)
  end

  def query
    p params

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
      
      states = nil

      # Find the state and return it in an array
      # => if All then return all active states
      if strong_params[:state_id] === "all"
        if strong_params[:project] == "SL"
          states = State.exclude_geom.active_sl.order(:name)
        elsif strong_params[:project] == "NRI"
          states = State.exclude_geom.active_nri.order(:name)
        else
          states = State.exclude_geom.active_naip.order(:name)
        end
      else
        states = State.exclude_geom.where(id: strong_params[:state_id])
      end

      result = []
      if states.size > 1
        scope = "state"
        states.each do |state|
          if strong_params[:project] == "SL" || strong_params[:project] == "NRI"
            result << state.wip_by_state(strong_params[:project], strong_params[:date_from], strong_params[:date_to])
          else
            result << state.naip_wip_by_state(strong_params[:date_from], strong_params[:date_to])
          end
        end
      else
        scope = "county"
        result = states.first.wip_by_state_counties(strong_params[:project], strong_params[:date_from], strong_params[:date_to])
      end

      render json: {
        scope: scope,
        result: result,
        pass: true
      }

    end

  end

  protected

  def strong_params
    params.permit(:project, :state_id, :date_from, :state_id, :date_to)
  end

end
