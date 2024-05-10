require 'test_helper'

class InvoiceNestidReportControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get invoice_nestid_report_index_url
    assert_response :success
  end

end
