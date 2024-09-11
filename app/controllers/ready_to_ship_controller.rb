class ReadyToShipController < ApplicationController
  authorize_resource :tiles

  def index
    @states = State.select(:id, :name).where(id: Tile.sl.county_flown.not_shipped.pluck(:state_id).uniq)
    @projects = Rails.application.secrets.active_projects
    @priorities = [
      {id: 0, value: "Overdue", color: "red"},
      {id: 1, value: "Due within 7 days", color: "orange"},
      {id: 2, value: "Due within 7-14 days", color: "yellow"},
      {id: 3, value: "Due within 15-30 days", color: "blue"},
    ]

    # Create History Record
    ReportHistory.create(name: "Ready to Ship", user: @current_user)
  end

  def query
    p params

    if params[:state_id].blank?
      return render json: {
        state: false,
        message: "Invalid State Parameter"
      }
    elsif params[:project].blank? || !Rails.application.secrets.active_projects.include?(params[:project])
      return render json: {
        state: false,
        message: "Invalid parameters, you must provide a State and Project in the query"
      }
    else

      result = []
      county_ids = []
      state_ids =[]
      totals = {
        state_count: 0,
        county_count: 0,
        remaining_count: 0,
        at_done_count: 0,
        ortho_proc_count: 0,
        dump_count: 0,
        county_tiles_count: 0,
        contract_total: 0,
      }
      current_date = Date.today
      scoped_priority = [0,1,2,3].include?(params[:priority]) ? params[:priority].to_i : "ALL"

      # select all or scoped counties by state
      counties = params[:state_id] == "ALL" ? County : State.find(params[:state_id]).counties

      # Query out the Tiles by county and proritize them based on the due date
      counties.includes(:tiles).where(id: Tile.where(project: params[:project]).county_flown.not_shipped.pluck(:county_id).uniq).each do |county|

        if params[:project] == "SL"
          tiles = county.tiles.sl
        elsif params[:project] == "NRI"
          tiles = county.tiles.nri
        end

        first = tiles.county_flown.not_shipped.first

        # check if overdue
        overdue = current_date >= first.county_due_date

        # Get the number of days
        days_til_due = (first.county_due_date - current_date).to_i

        if overdue
          priority = 0
        elsif days_til_due <= 7
          priority = 1
        elsif days_til_due <= 14
          priority = 2
        else
          priority = 3
        end

        # If the user scopes the priorities then skip if the priority does not match
        # => ALL allows all priorities to render
        next if scoped_priority != "ALL" && scoped_priority != priority

        obj = {
          county_id: county.id,
          name: county.name,
          state: first.state_name,
          county_flown_date: first.county_flown_date,
          county_flown_date_formatted: first.county_flown_date.strftime("%m/%d/%Y"),
          due_date: first.county_due_date,
          due_date_formatted: first.county_due_date.strftime("%m/%d/%Y"),
          days_til_due: days_til_due,
          priority: priority,
          num_tiles: tiles.county_flown.not_shipped.count,
          at_done: tiles.at_started.count,
          ortho_processed: tiles.ortho_processed.count,
          dumped: tiles.dumped.count,
          total_tiles: tiles.count,
          total_amount: tiles.county_flown.not_shipped.sum(:total_amount).to_f
        }

        # Calculate totals
        totals[:remaining_count] += obj[:num_tiles]
        totals[:at_done_count] += obj[:at_done]
        totals[:ortho_proc_count] += obj[:ortho_processed]
        totals[:dump_count] += obj[:dumped]
        totals[:county_tiles_count] += obj[:total_tiles]
        totals[:contract_total] += obj[:total_amount]

        # push county and state to array if not there already
        county_ids |= [county.id]
        state_ids |= [first.state_id]

        result << obj

      end

      # county the unique state and counties
      totals[:county_count] += county_ids.size
      totals[:state_count] += state_ids.size


      return render json: {
        result: result.sort{ |a, b| a[:days_til_due] <=> b[:days_til_due] },
        totals: totals,
        state: true
      }

    end

  end

  def show
    p params

    county = County.find_by(id: params[:county_id])

    if county.nil?
      @message = "Could not found County with specified ID"
    else

      @meta = {
        county_name: county.name,
        state_name: county.state.name
      }

      if county.tiles.count == 0
        @message = "#{county.name} County does not have any Tiles"
      else
        @tiles = []
  
        county.tiles.each do |tile|
          @tiles << {
            id: tile.id, 
            project: tile.project,
            easement_no: tile.poly_id,
            flight_date: tile.flight_date,
            flight_date_formatted: tile.flight_date ? tile.flight_date.strftime("%m/%d/%Y") : " - ",
            at_done_date: tile.at_done_date,
            at_done_date_formatted: tile.at_done_date ? tile.at_done_date.strftime("%m/%d/%Y") : " - ",
            ortho_proc_date: tile.ortho_proc_date,
            ortho_proc_formatted: tile.ortho_proc_date ? tile.ortho_proc_date.strftime("%m/%d/%Y") : " - ",
            dump_date: tile.dump_date,
            dump_date_formatted: tile.dump_date ? tile.dump_date.strftime("%m/%d/%Y") : " - ",
            ship_date: tile.ship_date,
            ship_date_formatted: tile.ship_date ? tile.ship_date.strftime("%m/%d/%Y") : " - ",
            flown_by: tile.flown_by_alias,
            plane: tile.plane_name,
            camera: tile.camera_name,
            county_flown_date: tile.county_flown_date,
            county_flown_date_formatted: tile.county_flown_date ? tile.county_flown_date.strftime("%m/%d/%Y") : " - ",
            county_due_date: tile.county_due_date,
            county_due_date_formatted: tile.county_due_date ? tile.county_due_date.strftime("%m/%d/%Y") : " - "
          }
        end
      end

    end

  end

end
