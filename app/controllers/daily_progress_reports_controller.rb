class DailyProgressReportsController < ApplicationController
    authorize_resource :footprints

    def index
        # Get the active flight dates that have not been reported
        @flight_dates = build

        # Create History Record
        ReportHistory.create(name: "Daily Progress report", user: @current_user)
    end

    def show
        p params
        # Select the contract type and build the results

        # Check that the params are set
        if params[:flight_date].blank?
            render json: {
                state: false,
                message: "Missing Flight Date Paramter"
            }
        end

        # Parse the Flight Date
        flight_date = Date.strptime(params[:flight_date], "%F")
        # rejected_date_from = params[:rejected_date_from].present? ? Date.strptime(params[:rejected_date_from], "%m/%d/%Y") : nil
        # rejected_date_to = params[:rejected_date_to].present? ? Date.strptime(params[:rejected_date_to], "%m/%d/%Y") : nil

        if !flight_date
            render json: {
                state: false,
                message: "Invalid Flight Date"
            }
        else
            result = DailyProgressReport.generate flight_date, current_user

            p result
    
            # Testing
            # Tile.reported.update(report_date: nil)
            # RejectedTile.all.update(report_date: nil, rejection_report_date: nil)
    
            render json: {
                result: result,
                flight_dates: build
            }
        end

    end

    private

    def build
        # Get yesterday's date
        yesterday = Date.yesterday.strftime("%F")

        # Get the non-reported tiles and rejected tiles that were older or equal to yesterday
        # associate_dates = Tile.sl.flown.not_reported.where.not(associate_date: nil).pluck(:associate_date).uniq
        associate_dates = Tile.sl.flown.not_reported.where("associate_date <= '#{yesterday}'").order(:associate_date).pluck(:associate_date).uniq
        flight_dates = Tile.sl.flown.not_reported.where("flight_date <= '#{yesterday}' AND associate_date is NULL").order(:flight_date).pluck(:flight_date).uniq
        # rejected_dates = RejectedTile.sl.flown.reported.rejection_not_reported.where("rejected_date <= '#{yesterday}'").order(:rejected_date).pluck(:rejected_date).uniq

        # Get only the unique flight dates
        # dates = flight_dates | rejected_dates | associate_dates
        dates = flight_dates | associate_dates

        return dates.sort.map {|flight_date| {value: flight_date.strftime("%F"), label: flight_date.strftime("%m/%d/%Y")}}
    end

end