require 'test_helper'

class UsdaRejectedControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get usda_rejected_index_url
    assert_response :success
  end

  test "should get create" do
    get usda_rejected_create_url
    assert_response :success
  end

end
