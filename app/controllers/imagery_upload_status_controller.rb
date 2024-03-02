class ImageryUploadStatusController < ApplicationController

    def index
        redirect_to root_path if !Rails.application.secrets.active_projects.include? "NAIP"
        @projects = Rails.application.secrets.active_projects
        if Date.today.sunday?
            @date_to = Date.today.strftime("%m/%d/%Y")
            @date_from = (Date.today - 7.days).strftime("%m/%d/%Y")
        else
            @date_to = Date.today.prev_occurring(:sunday).strftime("%m/%d/%Y")
            @date_from = (Date.today.prev_occurring(:sunday) - 6.days).strftime("%m/%d/%Y")
        end

        @vectorMetadatas = VectorMetadatum.includes(:footprints, :doqqs).naip.order(:flight_date).map do |vm|
            {
                state_name: vm.state_name,
                flight_date: vm.flight_date.strftime("%m/%d/%Y"),
                provisional_count: vm.footprints.count,
                provisional_date: vm.provisional_date ? vm.provisional_date.strftime("%m/%d/%Y") : "NA",
                provisional_due_date: vm.provisional_due_date ? vm.provisional_due_date.strftime("%m/%d/%Y") : "NA",
                production_count: vm.doqqs.count,
                production_upload_date: vm.production_date ? vm.production_date.strftime("%m/%d/%Y") : "NA"

            }
        end

    end

    def query
        p params

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

        response = VectorMetadatum.query params[:project], params[:date_from], params[:date_to]

        render json: response

    end

    def download
        p params

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

        # response = VectorMetadatum.query params[:project], params[:date_from], params[:date_to], true

        # p "-----------"
        # p response
        # p "-----------"

        send_data VectorMetadatum.query(params[:project], params[:date_from], params[:date_to], true), 
            filename: "ASI #{params[:project]} EAWS Imagery Upload Status (#{params[:date_from]} - #{params[:date_to]}).csv" 

    end


end