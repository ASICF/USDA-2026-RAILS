require 'test_helper'

class PhotoIndexTrackerControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get photo_index_tracker_index_url
    assert_response :success
  end

end
