require 'test_helper'

class ShippedTotalsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shipped_totals_index_url
    assert_response :success
  end

  test "should get show" do
    get shipped_totals_show_url
    assert_response :success
  end

end
