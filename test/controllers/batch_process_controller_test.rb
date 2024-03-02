require 'test_helper'

class BatchProcessControllerTest < ActionDispatch::IntegrationTest
  test "should get check_input" do
    get batch_process_check_input_url
    assert_response :success
  end

  test "should get checkout_output" do
    get batch_process_checkout_output_url
    assert_response :success
  end

  test "should get get_files_in_path" do
    get batch_process_get_files_in_path_url
    assert_response :success
  end

end
