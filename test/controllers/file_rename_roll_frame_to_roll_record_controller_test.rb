require 'test_helper'

class FileRenameRollFrameToRollRecordControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get file_rename_roll_frame_to_roll_record_index_url
    assert_response :success
  end

  test "should get create" do
    get file_rename_roll_frame_to_roll_record_create_url
    assert_response :success
  end

end
