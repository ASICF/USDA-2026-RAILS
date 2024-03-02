require 'test_helper'

class FileRotateControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get file_rotate_index_url
    assert_response :success
  end

  test "should get execute" do
    get file_rotate_execute_url
    assert_response :success
  end

end
