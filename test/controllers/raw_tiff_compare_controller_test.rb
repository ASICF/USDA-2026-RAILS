require 'test_helper'

class RawTiffCompareControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get raw_tiff_compare_index_url
    assert_response :success
  end

end
