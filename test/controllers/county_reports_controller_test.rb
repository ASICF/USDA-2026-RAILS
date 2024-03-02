require 'test_helper'

class CountyReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get county_reports_index_url
    assert_response :success
  end

  test "should get show" do
    get county_reports_show_url
    assert_response :success
  end

end
