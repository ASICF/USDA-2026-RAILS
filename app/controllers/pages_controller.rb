class PagesController < ApplicationController
  include GraphApiHelper
  include ActionView::Helpers::DateHelper
  include ActiveSupport::NumberHelper
  # before_action :authenticate_user!
  # authorize_resource class: false
  skip_before_action :authenticate_user!, only: [:tracker]
  skip_authorize_resource only: [:index, :tracker]
  
  def index
    @recent_activities = []
    History.last(30).reverse_each do |record|
      @recent_activities << {
        user: record.creator.full_name,
        action_type: record.action_type,
        created_at: record.created_at.strftime("%m/%d/%Y %I:%M %p"),
        time_offset: distance_of_time_in_words(Time.new, record.created_at)
      }
    end

    if Tile.flown.count > 0
      # build the date range for the Production Status Chart
      start_date = Tile.flown.order(:flight_date).first.flight_date
      if Tile.shipped.count > 0
        end_date = Tile.shipped.order(:ship_date).last.ship_date
      else
        end_date = Tile.flown.order(:flight_date).last.flight_date
      end
      @month_range = get_months_between_dates(start_date, end_date)
      @sl_states = State.select(:id, :name).active_sl.order(:name)
      @nri_states = State.select(:id, :name).active_nri.order(:name)
    else
      @month_range = []
      @states = []
    end

    # SL
    if Rails.application.secrets.active_projects.include? "SL"
      @sl = {
        states: State.active_sl.count,
        counties: Tile.sl.pluck(:county_id).uniq.count,
        tile_count: number_to_delimited(Tile.sl.count),
        tile_flown: number_to_delimited(Tile.sl.flown.count),
        acres_count: number_to_delimited(Tile.sl.sum(:easements_acres).round(2)),
        acres_flown: number_to_delimited(Tile.sl.flown.sum(:easements_acres).round(2)),
        acres_percentage: ((Tile.sl.flown.sum(:easements_acres).to_f / Tile.sl.sum(:easements_acres).to_f).to_f * 100).round(1),
        flown: ((Tile.sl.flown.count.to_f / Tile.sl.count.to_f).to_f * 100).round(1),
        tile_shipped: number_to_delimited(Tile.sl.shipped.count),
        shipped: ((Tile.sl.shipped.count.to_f / Tile.sl.count.to_f).to_f * 100).round(1),
      }
    else
      @sl = nil
    end

    # NRI
    if Rails.application.secrets.active_projects.include? "NRI"
      @nri = {
        states: State.active_nri.count,
        counties: Tile.nri.pluck(:county_id).uniq.count,
        tile_count: number_to_delimited(Tile.nri.count),
        tile_flown: number_to_delimited(Tile.nri.flown.count),
        acres_count: number_to_delimited(Tile.nri.sum(:easements_acres).round(2)),
        acres_flown: number_to_delimited(Tile.nri.flown.sum(:easements_acres).round(2)),
        acres_percentage: ((Tile.nri.flown.sum(:easements_acres).to_f / Tile.nri.sum(:easements_acres).to_f).to_f * 100).round(1),
        flown: ((Tile.nri.flown.count.to_f / Tile.nri.count.to_f).to_f * 100).round(1),
        tile_shipped: number_to_delimited(Tile.nri.shipped.count),
        shipped: ((Tile.nri.shipped.count.to_f / Tile.nri.count.to_f).to_f * 100).round(1),
      }
    else
      @nri = nil
    end

  end



  def tracker

    # Check if the token exists or not
    if params[:token]
      # Find the token in the Mailbox
      record = Mailbox.find_by(token: params[:token])

      # if the record exists then set the open date as of now and remove the token
      if record
        record.update(
          opened_at: Time.now,
          token: nil
        )
      end

    end

    # Always return a transparent image
    send_file(Rails.root.join("app", "assets", "images", "1x1.png"), type: "image/png", disposition: 'inline')
  end
end
