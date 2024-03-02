require 'test_helper'

class VectorMetadataControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vector_metadata_index_url
    assert_response :success
  end

  test "should get query" do
    get vector_metadata_query_url
    assert_response :success
  end

  test "should get export" do
    get vector_metadata_export_url
    assert_response :success
  end

end
