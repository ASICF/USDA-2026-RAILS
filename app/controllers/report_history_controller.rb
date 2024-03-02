class ReportHistoryController < ApplicationController
  include ApplicationHelper
  before_action :admin_check 
  skip_before_action :verify_authenticity_token
  def index
    # @reports = ReportHistory.all.order(:name).pluck(:name).uniq
    @users = ReportHistory.all.includes(:user).order("users.last_name DESC").pluck(:user_id).uniq.map {|id| User.find(id)}

    @reports = []
    ReportHistory.all.order(:name).pluck(:name).uniq.each do |name|

      # get the last report matching the name
      last = ReportHistory.where(name: name).last
      count = ReportHistory.where(name: name).count

      @reports << {
        name: name,
        last_ran_at: last.created_at,
        count: count
      }
    end
  end

  def show
    # Accept the name of the report
    if !params[:name]
      render json: {
        state: false,
        message: "Request did not include the Name of the report to query"
      }
    else

      # get the report 
      response = ReportHistory.build_report params[:name]

      render json: {
        state: response[:state],
        message: response[:message],
        records: response[:records],
        calendar: response[:calendar]
      }

    end
  end
end
