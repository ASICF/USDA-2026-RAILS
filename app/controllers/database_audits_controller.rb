class DatabaseAuditsController < ApplicationController

    def index
        # Create History Record
        ReportHistory.create(name: "Database Audit", user: @current_user)
    end

end
