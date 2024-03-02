class TotalDeliveryByStateAndContractorController < ApplicationController
  def index
    @states = State.exclude_geom.includes(easements: [:tiles]).active.order(:name)
    @months = Tile.flown.shipped.select(:ship_date).order(:ship_date).map{|record| {month: record.ship_date.month, year: record.ship_date.year, start_of_month: record.ship_date.beginning_of_month, end_of_month: record.ship_date.end_of_month, label: "#{record.ship_date.strftime("%B")} #{record.ship_date.year}"}}.uniq
    @company = Company.select(:id, :name, :alias).all.order(:name)
    @projects = Rails.application.secrets.active_projects

    # Create History Record
    ReportHistory.create(name: "Total Delivery by State and Contractor", user: @current_user)
  end

  def execute

    obj = {
      result: {},
      pass: "",
      message: "",
      project: ""
    }

    if params[:state_id].blank?
        obj[:message] = "No State Selected"
        obj[:status] = "Error"
    elsif params[:company_id].blank?
        obj[:message] = "No Specified Company"
        obj[:status] = "Error"
    elsif params[:project].blank?
        obj[:message] = "No Project Specified"
        obj[:status] = "Error"
    elsif params[:from_date].blank? || params[:to_date].blank?
        obj[:message] = "Invalid ship date range"
        obj[:status] = "Error"
    else

        if params[:company_id] == "ALL"
          companies = Company.all.order(:name)
        else
          companies = Company.where(id: params[:company_id])
        end
    
        date_from = Time.parse(params[:from_date]).to_datetime
        date_to = Time.parse(params[:to_date]).to_datetime

        obj[:project] = params[:project]

        if params[:project] == "SL"
          sl_execute params, obj, companies, date_from, date_to
        elsif params[:project] == "NAIP"
          naip_execute params, obj, companies, date_from, date_to
        end

    end

    render json: obj

  end

  private

  def sl_execute params, obj, companies, date_from, date_to

    if params[:state_id] == "ALL"
      states = State.active_sl
      label = "All"
    else
      states = State.where(id: params[:state_id])
      label = states.first.name
    end

    # Iterate companies
    # Iterate states
    # Calculate totals for each state and company within ship_date range

    company_obj = {}

    companies.each do |company|

      states.each do |state|

        (date_from..date_to).map{|d| [d.beginning_of_month, d.end_of_month]}.uniq.each do |d|

          start_of_month = d[0]
          end_of_month = d[1]

          # scoped_nri_tiles = state.tiles.nri.shipped.where(ship_date: start_of_month..end_of_month, flown_by: company).count
          scoped_tiles = state.tiles.sl.shipped.where(ship_date: start_of_month..end_of_month, flown_by: company)

          next if scoped_tiles.count == 0

          company_obj[company.name.to_sym] = [] unless company_obj[company.name.to_sym].present?

          company_obj[company.name.to_sym] << {
            month: "#{start_of_month.strftime("%B")} #{start_of_month.year}",
            state: state.name,
            total_acres: Easement.where(poly_id: scoped_tiles.map(&:poly_id)).map(&:acres).inject(0, &:+).to_f,
            total_shipped: scoped_tiles.count
          }

        end

      end

    end

    obj[:result] = Array.wrap(company_obj)

    if obj[:result].empty?
      obj = {
        status: "Info",
        message: "No tiles were shipped based on the specified arguements."
      }
    else
      obj[:status] = "Success"
    end

    obj

  end

  # def naip_execute params, obj, companies, date_from, date_to

  #   if params[:state_id] == "ALL"
  #     states = State.active_sl
  #     label = "All"
  #   else
  #     states = State.where(id: params[:state_id])
  #     label = states.first.name
  #   end

  #   # Iterate companies
  #   # Iterate states
  #   # Calculate totals for each state and company within ship_date range

  #   company_obj = {}

  #   companies.each do |company|

  #     states.each do |state|

  #       (date_from..date_to).map{|d| [d.beginning_of_month, d.end_of_month]}.uniq.each do |d|

  #         start_of_month = d[0]
  #         end_of_month = d[1]

  #         # scoped_nri_tiles = state.tiles.nri.shipped.where(ship_date: start_of_month..end_of_month, flown_by: company).count
  #         scoped_tiles = state.doqqs.shipped.where(ship_date: start_of_month..end_of_month)

  #         next if scoped_tiles.count == 0

  #         company_obj[company.name.to_sym] = [] unless company_obj[company.name.to_sym].present?

  #         company_obj[company.name.to_sym] << {
  #           month: "#{start_of_month.strftime("%B")} #{start_of_month.year}",
  #           state: state.name,
  #           total_shipped: scoped_tiles.count
  #         }

  #       end

  #     end

  #   end

  #   obj[:result] = Array.wrap(company_obj)

  #   if obj[:result].empty?
  #     obj = {
  #       status: "Info",
  #       message: "No tiles were shipped based on the specified arguements."
  #     }
  #   else
  #     obj[:status] = "Success"
  #   end

  #   obj

  # end
end
