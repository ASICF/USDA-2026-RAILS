class PagesController < ApplicationController
  include GraphApiHelper
  include ActionView::Helpers::DateHelper
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
    # build the date range for the Production Status Chart
    start_date = Tile.flown.order(:flight_date).first.flight_date
    if Tile.shipped.count > 0
      end_date = Tile.shipped.order(:ship_date).last.ship_date
    else
      end_date = Tile.flown.order(:flight_date).last.flight_date
    end
    @month_range = get_months_between_dates(start_date, end_date)
    @states = State.select(:id, :name).active_sl.order(:name)
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
