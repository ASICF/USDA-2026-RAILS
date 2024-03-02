require 'test_helper'

class EoTrackerControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get eo_tracker_index_url
    assert_response :success
  end

  test "should get show" do
    get eo_tracker_show_url
    assert_response :success
  end

end
