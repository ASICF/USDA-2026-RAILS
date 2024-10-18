require 'test_helper'

class EoSplitterControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get eo_splitter_index_url
    assert_response :success
  end

  test "should get execute" do
    get eo_splitter_execute_url
    assert_response :success
  end

end
