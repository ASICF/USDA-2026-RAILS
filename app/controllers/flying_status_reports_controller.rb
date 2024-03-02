class FlyingStatusReportsController < ApplicationController
  authorize_resource :tiles
  
  def index
    # @states = State.active
    # @months = Tile.flown.select(:flight_date).map{|record| record.flight_date.month}.uniq

    @states = State.select(:id, :name).active
    flight_dates = Tile.flown.select(:flight_date).pluck(:flight_date).uniq + Doqq.flown.select(:flight_date).pluck(:flight_date).uniq
    @months = flight_dates.sort.map{|record| {date: record.beginning_of_month, name: record.strftime("%B %Y") }}.uniq
    @projects = Rails.application.secrets.active_projects

    # Create History Record
    ReportHistory.create(name: "Flying Status Report", user: @current_user)
  end

  def show
    build_report
  end

  def export
  end

  private

  def build_report

    if params[:scope_id].blank?
      return render json: {
        state: false,
        message: "No Scope provided"
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

    # Get the beginning and ending of the date range in UTC
    date_flown_from = Time.parse(params[:date_from]).utc.beginning_of_day
    date_flown_end = Time.parse(params[:date_to]).utc.end_of_day

    response = {
      state: false, 
      message: "Somewhing went wrong",
      result: [],
      project: params[:project]
    }

    # Query by Post Flight Records now, get unqiue companies using the flown_by field
    if params[:scope_id] == "CONTRACTOR"

      response[:scope] = "CONTRACTOR"

      if params[:project] == "SL"
        response[:result] = FlyingStatusReport.AllSitesByContractorSl date_flown_from, date_flown_end
      else
        response[:result] = FlyingStatusReport.AllSitesByContractorNAIP date_flown_from, date_flown_end
      end

      return render json: response

    elsif params[:scope_id] == "STATE"

      response[:scope] = "STATE"

      if params[:project] == "SL"
        response[:result] = FlyingStatusReport.AllSitesByStateSL date_flown_from, date_flown_end
      else
        response[:result] = FlyingStatusReport.AllSitesByStateNAIP date_flown_from, date_flown_end
      end

      return render json: response

    elsif params[:scope_id] == "CONTRACTOR_STATE"

      response[:scope] = "CONTRACTOR_STATE"

      if params[:project] == "SL"
        response[:result] = FlyingStatusReport.AllSitesByContractorAndStateSL date_flown_from, date_flown_end
      else
        response[:result] = FlyingStatusReport.AllSitesByContractorAndStateNAIP date_flown_from, date_flown_end
      end

      return render json: response

    else
      state = State.find(params[:scope_id])

      response[:scope] = "OTHER"

      if params[:project] == "SL"
        
        response[:result] = FlyingStatusReport.otherSl state, date_flown_from, date_flown_end

      elsif params[:project] == "NAIP"

        response[:result] = FlyingStatusReport.otherNaip state, date_flown_from, date_flown_end

      end

      return render json: response

    end

    return render json: {
      state: false,
      message: "No Project Type provided"
    }

  end
end
