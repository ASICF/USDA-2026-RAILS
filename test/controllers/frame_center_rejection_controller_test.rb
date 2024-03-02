require 'test_helper'

class FrameCenterRejectionControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get frame_center_rejection_index_url
    assert_response :success
  end

  test "should get export" do
    get frame_center_rejection_export_url
    assert_response :success
  end

end
