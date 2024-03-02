require 'test_helper'

class ContractorBreakdownByStateControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get contractor_breakdown_by_state_index_url
    assert_response :success
  end

  test "should get show" do
    get contractor_breakdown_by_state_show_url
    assert_response :success
  end

end
