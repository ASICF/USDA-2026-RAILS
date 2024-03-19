class WeeklyProgressReportsController < ApplicationController
  authorize_resource :footprints

  def index
    @projects = Rails.application.secrets.active_projects
    @path = Rails.application.secrets.weekly_progress_folder_p_path
  end

  def generate
    pp params

    if params[:project].blank?
      return render json: {
        state: false,
        message: "No Project Type provided"
      }
    else

      response = WeeklyProgressReport.generate params[:project], current_user

      render json: response

    end
  end

end
