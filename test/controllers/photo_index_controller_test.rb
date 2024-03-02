require 'test_helper'

class PhotoIndexControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get photo_index_index_url
    assert_response :success
  end

end
