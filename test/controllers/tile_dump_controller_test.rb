require 'test_helper'

class TileDumpControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get tile_dump_new_url
    assert_response :success
  end

  test "should get upload" do
    get tile_dump_upload_url
    assert_response :success
  end

end
