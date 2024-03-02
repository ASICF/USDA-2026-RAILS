require 'test_helper'

class SitesToBeReflownControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sites_to_be_reflown_index_url
    assert_response :success
  end

  test "should get show" do
    get sites_to_be_reflown_show_url
    assert_response :success
  end

end
