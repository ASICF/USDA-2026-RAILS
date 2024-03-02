require 'test_helper'

class ExportFrameCentersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get export_frame_centers_index_url
    assert_response :success
  end

  test "should get generate" do
    get export_frame_centers_generate_url
    assert_response :success
  end

end
