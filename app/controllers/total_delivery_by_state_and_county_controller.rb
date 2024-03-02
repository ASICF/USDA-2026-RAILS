class TotalDeliveryByStateAndCountyController < ApplicationController

  def index
    @states = State.includes(:tiles).active_sl.order(:name).map do |state|
      {
        id: state.id,
        name: state.name,
        abv: state.abv,
        total: state.tiles.count,
        flown: state.tiles.flown.count,
        at_done: state.tiles.at_done.count,
        ortho_processed: state.tiles.ortho_processed.count,
        shipped: state.tiles.shipped.count,
        usda_accepted: state.tiles.usda_accepted.count,
        invoiced: state.tiles.invoiced.count,
      }
    end

    # Create History Record
    ReportHistory.create(name: "Total Delivery by State and Counties", user: @current_user)

  end

  def show
    @state = State.find_by(abv: params[:state_abv])
    # County, Due Date, Shipped Date, Shipped Total, USDA Approved, Invoiced Date, Awarded, and Cost
    @counties = []
    @state.counties.includes(:tiles).active.each do |county|
      # Get the first tile from the county
      first = county.tiles.first
      # return a new object
      @counties << {
        name: county.name,
        due_date: county.tiles.county_due_set.count === county.tiles.count ? first.county_due_date : nil,
        ship_date: county.tiles.shipped.count === county.tiles.count ? first.ship_date : nil,
        total_ready_to_ship: county.tiles.ready_to_ship.count,
        ship_total: county.tiles.shipped.count,
        usda_approved: county.tiles.usda_accepted.count,
        invoiced_date: county.tiles.invoiced.count === county.tiles.count ? first.invoiced_date : nil,
        total_invoiced: county.tiles.invoiced.count,
        total: county.tiles.count,
      }
    end
    # Create History Record
    ReportHistory.create(name: "Total Delivery by State and Counties", user: @current_user)
  end

end