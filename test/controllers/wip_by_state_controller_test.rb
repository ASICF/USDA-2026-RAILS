require 'test_helper'

class WipByStateControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get wip_by_state_index_url
    assert_response :success
  end

  test "should get show" do
    get wip_by_state_show_url
    assert_response :success
  end

end
