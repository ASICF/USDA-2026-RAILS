class PackingSlipWorksheetController < ApplicationController
    authorize_resource :tiles

    def index
        @psns = []
        PackingSlip.all.order(name: :desc).each do |psn|
            psn_as_json = psn.as_json
            psn_as_json["tile_count"] = psn.tiles.count
            psn_as_json["doqqs_count"] = psn.doqqs.count

            state_ids = psn.tiles.pluck(:state_id).uniq + psn.doqqs.pluck(:state_id).uniq

            psn_as_json["states"] = State.select(:name).where(id: state_ids).pluck(:name).join(", ")
            @psns << psn_as_json
        end

        # Create History Record
        ReportHistory.create(name: "Packing Slip Worksheets", user: @current_user)
    end

    def show
        @packing_slip = PackingSlip.find(params[:psn])
    end

    def export
        @packing_slip = PackingSlip.find(params[:psn])
        respond_to do |format|
            format.html
            format.pdf do
                render pdf:     "test",
                show_as_html:   params.key?('debug')
            end
        end
    end

end
