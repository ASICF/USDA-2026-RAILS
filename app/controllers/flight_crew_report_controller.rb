class FlightCrewReportController < ApplicationController
  def index
    @states = State.select(:id, :name).active
    flight_dates = Tile.flown.select(:flight_date).pluck(:flight_date).uniq + Doqq.flown.select(:flight_date).pluck(:flight_date).uniq
    @months = flight_dates.sort.map{|record| {date: record.beginning_of_month, name: record.strftime("%B %Y") }}.uniq
    @contractors = Company.select(:id, :name).all
    @projects = Rails.application.secrets.active_projects

    # Create History Record
    ReportHistory.create(name: "Flight Crew", user: @current_user)
  end

  def query

    if params[:state_id].blank?
      return render json: {
        state: false,
        message: "No State provided"
      }
    elsif params[:flown_by_id].blank?
      return render json: {
        state: false,
        message: "No Company provided"
      }
    elsif params[:date_from].blank?
      return render json: {
        state: false,
        message: "No Date From provided"
      }
    elsif params[:date_to].blank?
      return render json: {
        state: false,
        message: "No Date To provided"
      }
    elsif params[:project].blank?
      return render json: {
        state: false,
        message: "No Project Type provided"
      }
    end

    response = {
      state: false, 
      message: "Somewhing went wrong",
      result: [],
      project: params[:project]
    }

    # Get the beginning and ending of the date range in UTC
    date_flown_from = Time.parse(params[:date_from]).utc.beginning_of_day
    date_flown_to = Time.parse(params[:date_to]).utc.end_of_day

    # Get the companies
    if params[:flown_by_id] == "ALL"
      companies = Company.all
    else
      companies = Company.where(id: params[:flown_by_id])
    end

    # Get the states
    if params[:state_id] == "ALL"
      states = State.exclude_geom.active_sl
    else
      states = Company.where(id: params[:flown_by_id])
    end

    if params[:project] == "SL"
      states = params[:state_id] == "ALL" ? State.exclude_geom.active_sl : State.exclude_geom.where(id: params[:state_id])
      response[:result] = Tile.flight_crew_report companies, states, date_flown_from, date_flown_to
    else
      states = params[:state_id] == "ALL" ? State.exclude_geom.active_naip : State.exclude_geom.where(id: params[:state_id])
      response[:result] = Doqq.flight_crew_report companies, states, date_flown_from, date_flown_to
    end

    return render json: response
  end

end
