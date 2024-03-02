class ContractorBreakdownByStateController < ApplicationController
  def index
    @states = State.active.select(:id, :name).order("states.name ASC")
    @companies = Company.all.order(:name)
    @months = Tile.flown.select(:flight_date).map{|record| record.flight_date.month}.uniq

    # Create History Record
    ReportHistory.create(name: "Contractor Breakdown by State", user: @current_user)
  end

  def show
    build
  end

  private

  def build

      if params[:state_id].blank?
        flash[:error] = "No State provided"
        redirect_to contractor_breakdown_by_state_path
      elsif params[:contractor_id].blank?
        flash[:error] = "No Contractor provided"
        redirect_to contractor_breakdown_by_state_path
      elsif params[:date_flown_from].blank?
        flash[:error] = "No Flown Start Date provided"
        redirect_to contractor_breakdown_by_state_path
      elsif params[:date_flown_from].blank?
        flash[:error] = "No Flown End Date provided"
        redirect_to contractor_breakdown_by_state_path
      elsif params[:project].blank?
        flash[:error] = "No Project Type provided"
        redirect_to contractor_breakdown_by_state_path
      end

      # Get the beginning and ending of the date range in UTC
      @date_flown_from = Time.parse(params[:date_flown_from]).utc.beginning_of_day
      @date_flown_end = Time.parse(params[:date_flown_end]).utc.end_of_day
  
      # Save the project
      @project = params[:project] == "All" ? Rails.application.secrets.active_projects : params[:project]

      if params[:state_id] == "ALL"
        # Return configs that have Post Flight Records flown during that period
        if params[:contractor_id] == "ALL"
          # @configs = Config.includes(:post_flight_records).where(post_flight_records: {flight_date: @date_flown_from..@date_flown_end}).order(:state_name)
          # @states = State.joins(:tiles).exclude_geom.where(tiles: {flight_date: @date_flown_from..@date_flown_end, project: @project}).order(:name)
          # @states = State.includes(:tiles).exclude_geom.where(id: Tile.select(:state_id).where(flight_date: date_flown_from..date_flown_end, project: "SL").pluck(:state_id).uniq)
          @states = State.includes(:tiles).where(id: Tile.select(:state_id).where(flight_date: @date_flown_from..@date_flown_end, project: @project).pluck(:state_id).uniq)
        else
          # @configs = Config.includes(:post_flight_records).where(post_flight_records: {flight_date: @date_flown_from..@date_flown_end, flown_by_id: params[:contractor_id]}).order(:state_name)
          # @states = State.includes(:tiles).where(tiles: {flight_date: @date_flown_from..@date_flown_end, project: @project, flown_by_id: params[:contractor_id]}).order(:name)
          @states = State.includes(:tiles).where(id: Tile.select(:state_id).where(flight_date: @date_flown_from..@date_flown_end, project: @project, flown_by_id: params[:contractor_id]).pluck(:state_id).uniq)
        end
      else
        # @configs = [Config.includes(:post_flight_records).find(params[:state_id])]
        @states = [State.includes(:tiles).exclude_geom.find_by(id: params[:state_id], tiles: {project: @project})]
      end
  end
end
