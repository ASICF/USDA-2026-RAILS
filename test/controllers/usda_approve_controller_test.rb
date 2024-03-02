require 'test_helper'

class UsdaApproveControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get usda_approve_index_url
    assert_response :success
  end

  test "should get show" do
    get usda_approve_show_url
    assert_response :success
  end

  test "should get create" do
    get usda_approve_create_url
    assert_response :success
  end

end
