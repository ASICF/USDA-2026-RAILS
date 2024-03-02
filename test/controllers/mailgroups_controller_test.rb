require 'test_helper'

class MailgroupsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get mailgroups_index_url
    assert_response :success
  end

  test "should get action" do
    get mailgroups_action_url
    assert_response :success
  end

end
