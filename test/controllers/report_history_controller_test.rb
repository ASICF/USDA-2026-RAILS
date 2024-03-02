require 'test_helper'

class ReportHistoryControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get report_history_index_url
    assert_response :success
  end

end
