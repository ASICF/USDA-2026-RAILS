class InvoicesController < ApplicationController

    def index
        @invoices = []
        Invoice.includes(:packing_slips).all.each do |invoice|
            attr = invoice.attributes
            attr["packing_slips"] = invoice.packing_slips.count
            @invoices << attr
        end
    end

    def show
        @invoice = Invoice.find(params[:id])
        @packing_slips = []
        @invoice.packing_slips.each do |ps|
            attr = ps.attributes
            attr["tile_count"] = ps.tiles.count
            @packing_slips << attr
        end
    end

    def new
        @invoice = Invoice.new
        @packing_slips = []
        @selected_ps_ids = []
        PackingSlip.not_invoiced.each do |ps|
            attr = ps.attributes
            attr["tile_count"] = ps.tiles.count
            @packing_slips << attr
        end
        @projects = ["SL", "NRI"]
    end

    def edit
        @invoice = Invoice.find(params[:id])
        @selected_ps_ids = @invoice.packing_slips.pluck(:id)
        @packing_slips = []
        PackingSlip.where(id: @invoice.packing_slips.pluck(:id).concat(PackingSlip.not_invoiced.pluck(:id))).each do |ps|
            attr = ps.attributes
            attr["tile_count"] = ps.tiles.count
            @packing_slips << attr
        end

        @projects = ["SL", "NRI"]
    end

    def create
        pp invoice_params

        # create invoice
        invoice = Invoice.new({
            project: invoice_params[:project],
            number: invoice_params[:number],
            invoice_date: invoice_params[:invoice_date],
        })

        packing_slips = PackingSlip.not_invoiced.where(id: invoice_params[:packing_slips])

        # check if the packing slips projects are not the same as the invoice
        if packing_slips.where.not(project: invoice_params[:project]).count > 0

            render json: {
                state: false,
                message: "Selected Packing Slips contain more than one unique project"
            }
        else
                
            p "====="
            pp invoice

            if invoice.save

                # update packing slips
                if packing_slips.update(invoice_id: invoice.id)

                    # update the tiles invoice date
                    Tile.where(packing_slip_id: packing_slips.pluck(:id)).update(invoiced_date: invoice.invoice_date)

                    # build invoice claculation
                    invoice.calculate_total

                    render json: {
                        state: true,
                        message: "Successfully created Invoice and associated #{packing_slips.size} Packing Slips",
                        invoice_id: invoice.id
                    }
                else
                    invoice.destroy
                    render json: {
                        state: false,
                        message: "Could not update Packing Slips"
                    }
                end
            else
                render json: {
                    state: false,
                    message: invoice.errors.full_messages.to_sentence
                }
            end
        end
    end

    def update
        pp invoice_params

        # Update invoice values
        invoice = Invoice.find(params[:id])
        invoice.assign_attributes({
            project: invoice_params[:project],
            number: invoice_params[:number],
            invoice_date: invoice_params[:invoice_date],
        })

        p "+++++++"
        pp invoice

        if invoice.save
            # determine which packing slips are different and remove those packing slips and add any new values
            ps_ids = invoice.packing_slips.pluck(:id)

            # find the ids in the array that are not in 
            old_ids = ps_ids-invoice_params[:packing_slips]
            p "-----"
            p ps_ids
            p invoice_params[:packing_slips]
            p old_ids

            # remove any ids that are not in the returned packing slip id array
            if old_ids.size > 0
                invoice.packing_slips.where(id: old_ids).update(invoice_id: nil)
            end


            # update packing slips
            packing_slips = PackingSlip.not_invoiced.where(id: invoice_params[:packing_slips])

            if packing_slips.update(invoice_id: invoice.id)

                # update the tiles invoice date
                Tile.where(packing_slip_id: packing_slips.pluck(:id)).update(invoiced_date: invoice.invoice_date)

                # clear any existing tiles invoiced date if removed from invoice
                PackingSlip.not_invoiced.each {|ps| ps.tiles.update(invoiced_date: nil)}

                # build invoice claculation
                invoice.calculate_total

                render json: {
                    state: true,
                    message: "Successfully updated Invoice #{invoice.number} and associated #{invoice.packing_slips.size} Packing Slips"
                }
            else
                invoice.destroy
                render json: {
                    state: false,
                    message: "Could not update Packing Slips"
                }
            end
        else
            render json: {
                state: false,
                message: invoice.errors.full_messages.to_sentence
            }
        end
    end

    def export
        invoice = Invoice.find(params[:id])

        send_data invoice.export, filename: "Invoice #{invoice.number} Delivery Report #{invoice.project} (#{Time.now.in_time_zone("Central Time (US & Canada)").strftime('%Y-%m-%d_%H-%M-%S')}).csv" 
    end

    def destroy
        p params

        invoice = Invoice.find(params[:id])
        number = invoice.number

        # dissassoicate the packing slips
        invoice.packing_slips.update(invoice_id: nil)

        # clear any existing tiles invoiced date if removed from invoice
        PackingSlip.not_invoiced.each {|ps| ps.tiles.update(invoiced_date: nil)}

        # delete the invoice
        invoice.destroy

        render json: {
            state: true,
            message: "Destroyed #{number} Invoice and released all associated Packing Slips"
        }
    end

    private

    def invoice_params
        params.required(:invoice).permit(:id, :project, :number, :invoice_date, packing_slips: [])
    end

end
