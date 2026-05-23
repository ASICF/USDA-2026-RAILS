require 'test_helper'

class LoadoutsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get loadouts_index_url
    assert_response :success
  end

  test "should get new" do
    get loadouts_new_url
    assert_response :success
  end

  test "should get create" do
    get loadouts_create_url
    assert_response :success
  end

  test "should get edit" do
    get loadouts_edit_url
    assert_response :success
  end

  test "should get update" do
    get loadouts_update_url
    assert_response :success
  end

  test "should get destroy" do
    get loadouts_destroy_url
    assert_response :success
  end

end
