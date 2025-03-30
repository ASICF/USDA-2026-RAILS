require 'test_helper'

class FootprintTrackerControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get footprint_tracker_index_url
    assert_response :success
  end

end
