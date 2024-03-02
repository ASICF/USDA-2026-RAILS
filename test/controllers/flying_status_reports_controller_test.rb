require 'test_helper'

class FlyingStatusReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get flying_status_reports_index_url
    assert_response :success
  end

  test "should get show" do
    get flying_status_reports_show_url
    assert_response :success
  end

  test "should get export" do
    get flying_status_reports_export_url
    assert_response :success
  end

end
