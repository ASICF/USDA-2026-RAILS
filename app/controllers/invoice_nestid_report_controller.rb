class InvoiceNestidReportController < ApplicationController
  
  def index
    @invoices = Invoice.all
    @projects = ["SL", "NRI"]
  end

  def query
    p params

    if invoice_params[:invoice_id].blank?
        return render json: {
            state: false,
            message: "Missing Date From value"
        }
    else

        invoice = Invoice.find(invoice_params[:invoice_id])

        if invoice.nil?
          return render json: {
              state: false,
              message: "Invoice not found"
          }
        else

          response = invoice.nestid_report

          render json: response

        end


    end

  end

  def export
    p invoice_params
      if invoice_params[:invoice_id].blank?
          raise exception
      else


        invoice = Invoice.find(invoice_params[:invoice_id])

        if invoice.nil?
          return render json: {
              state: false,
              message: "Invoice not found"
          }
        else
          
          send_data invoice.nestid_export, filename: "Invoice #{invoice.number} NestID Report (#{Time.now.in_time_zone("Central Time (US & Canada)").strftime('%Y-%m-%d_%H-%M-%S')}).csv" 


        end

      end

    end

  private

  def invoice_params
      params.permit(:project, :invoice_id)
  end
end
