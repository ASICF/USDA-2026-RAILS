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
        @packing_slips = @invoice.packing_slips
    end

    def new
        @invoice = Invoice.new
        @packing_slips = []
        PackingSlip.not_invoiced.each do |ps|
            attr = ps.attributes
            attr["tile_count"] = ps.tiles.count
            @packing_slips << attr
        end
        @projects = ["SL", "NRI"]
    end

    def edit
    end

    def create
        pp invoice_params

        # create invoice
        invoice = Invoice.new({
            project: invoice_params[:project],
            number: invoice_params[:number],
            invoice_date: invoice_params[:invoice_date],
        })

        if invoice.save
            # update packing slips
            packing_slips = PackingSlip.not_invoiced.where(id: invoice_params[:packing_slips])

            if packing_slips.update(invoice_id: invoice.id)

                # build invoice claculation
                invoice.calculate_total

                render json: {
                    state: true,
                    message: "Successfully created Invoice and associated #{packing_slips.size} Packing Slips"
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

    def update
    end

    def destroy
    end

    private

    def invoice_params
        params.required(:invoice).permit(:project, :number, :invoice_date, packing_slips: [])
    end

end
