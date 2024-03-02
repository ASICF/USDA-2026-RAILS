class InvoicesController < ApplicationController

    def index
        # @months = Tile.shipped.select(:ship_date).map{|record| record.ship_date.month}.uniq
        # @months = Tile.shipped.select(:ship_date).order(:ship_date).map{|record| {date: record.ship_date.beginning_of_month, name: record.ship_date.strftime("%B %Y") }}.uniq
        @months = PackingSlip.select(:shipped_date).order(:shipped_date).map{|record| {date: record.shipped_date.beginning_of_month, name: record.shipped_date.strftime("%B %Y") }}.uniq
        @projects = Rails.application.secrets.active_projects
        @states = State.exclude_geom.select(:id, :name).where(id: Tile.shipped.pluck(:state_id).uniq).order(:name)
        @state_totals = State.active.map do |state| 
            {
                name: state.name, 
                easement_count: state.easements.count,
                easement_acres: state.easements.sum(&:acres),
                awarded: ContractAward.find_by(state_id: state.id).amount,
                total_cost: state.tiles.flown.sum(&:total_amount)
            }
        end

        # Create History Record
        ReportHistory.create(name: "Invoice", user: @current_user)
    end

    def query
        p params

        if invoice_params[:project].blank?
            return render json: {
                state: false,
                message: "No Project parameter found"
            }
        elsif invoice_params[:date_from].blank?
            return render json: {
                state: false,
                message: "Missing Date From value"
            }
        elsif invoice_params[:state_id].blank?
            return render json: {
                state: false,
                message: "Missing State"
            }
        elsif invoice_params[:date_to].blank?
            return render json: {
                state: false,
                message: "Missing Date To value"
            }
        end

        response = Invoice.build invoice_params[:project], invoice_params[:date_from], invoice_params[:date_to], invoice_params[:state_id]

        render json: response

    end

    def export
        if invoice_params[:project].blank? || invoice_params[:date_from].blank? || invoice_params[:date_to].blank? || invoice_params[:state_id].blank?
            raise exception
        end

        p invoice_params

        send_data Invoice.build(params[:project], params[:date_from], params[:date_to], params[:state_id], true), filename: "Invoice Report #{invoice_params[:project]} (#{Time.now.in_time_zone("Central Time (US & Canada)").strftime('%Y-%m-%d_%H-%M-%S')}).csv" 
    end

    private

    def build
        @date_flown_from = Time.parse(params[:date_from]).utc.beginning_of_day
        @date_flown_end = Time.parse(params[:date_to]).utc.end_of_day
    end

    def invoice_params
        params.permit(:project, :date_from, :date_to, :state_id)
    end

end
