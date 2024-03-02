class EawsUsageController < ApplicationController
    include ApplicationHelper

    def index
        redirect_to root_path if !Rails.application.secrets.active_projects.include? "NAIP"

        @projects = Rails.application.secrets.active_projects
        @services = ["Provisional", "Production"]
        if Date.today.sunday?
            @date_to = Date.today.strftime("%m/%d/%Y")
            @date_from = (Date.today - 7.days).strftime("%m/%d/%Y")
        else
            @date_to = Date.today.prev_occurring(:sunday).strftime("%m/%d/%Y")
            @date_from = (Date.today.prev_occurring(:sunday) - 6.days).strftime("%m/%d/%Y")
        end
    end

    def query
        p usage_params

        if params[:project].blank?
            return render json: {
                state: false,
                message: "No Project parameter found"
            }
        elsif params[:date_from].blank?
            return render json: {
                state: false,
                message: "Missing Date From value"
            }
        elsif params[:date_to].blank?
            return render json: {
                state: false,
                message: "Missing Date To value"
            }
        end

        response = WebLogSummary.query params[:project], params[:date_from], params[:date_to]

        render json: response

    end

    def export
        p usage_params

        if usage_params[:project].blank?
            return render json: {
                state: false,
                message: "No Project parameter found"
            }
        elsif usage_params[:date_from].blank?
            return render json: {
                state: false,
                message: "Missing Date From value"
            }
        elsif usage_params[:date_to].blank?
            return render json: {
                state: false,
                message: "Missing Date To value"
            }
        end

        response = WebLogSummary.export params[:project], params[:date_from], params[:date_to], current_user

        render json: response
    end

    def download

        history = History.find(params[:history_id])

        if history.nil?
            raise exception
        end

        send_file(
            history.url,
            filename: File.basename(history.url),
            type: "application/xlsx"
        )
    end

    private

    def usage_params
        params.permit(:project, :date_from, :date_to)
    end

end