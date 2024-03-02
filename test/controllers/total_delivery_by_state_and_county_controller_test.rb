require 'test_helper'

class TotalDeliveryByStateAndCountyControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get total_delivery_by_state_and_county_index_url
    assert_response :success
  end

  test "should get show" do
    get total_delivery_by_state_and_county_show_url
    assert_response :success
  end

end
