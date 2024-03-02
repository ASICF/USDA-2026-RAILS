require 'test_helper'

class TileStatusControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tile_status_index_url
    assert_response :success
  end

  test "should get show" do
    get tile_status_show_url
    assert_response :success
  end

end
