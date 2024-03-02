require 'test_helper'

class ReadyToShipControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ready_to_ship_index_url
    assert_response :success
  end

  test "should get show" do
    get ready_to_ship_show_url
    assert_response :success
  end

end
