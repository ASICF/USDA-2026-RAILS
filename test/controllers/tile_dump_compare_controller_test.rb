require 'test_helper'

class TileDumpCompareControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tile_dump_compare_index_url
    assert_response :success
  end

  test "should get execute" do
    get tile_dump_compare_execute_url
    assert_response :success
  end

end
