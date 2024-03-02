require 'test_helper'

class FlightCrewReportControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get flight_crew_report_index_url
    assert_response :success
  end

  test "should get show" do
    get flight_crew_report_show_url
    assert_response :success
  end

end
