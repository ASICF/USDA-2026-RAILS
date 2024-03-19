require 'test_helper'

class WeeklyProgressReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get weekly_progress_reports_index_url
    assert_response :success
  end

end
