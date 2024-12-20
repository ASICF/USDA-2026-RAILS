require 'test_helper'

class FinalDeliverySplitControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get final_delivery_split_index_url
    assert_response :success
  end

end
