require 'test_helper'

class UnrejectTileControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get unreject_tile_index_url
    assert_response :success
  end

  test "should get show" do
    get unreject_tile_show_url
    assert_response :success
  end

  test "should get execute" do
    get unreject_tile_execute_url
    assert_response :success
  end

end
