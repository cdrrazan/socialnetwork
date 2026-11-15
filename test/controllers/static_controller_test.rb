require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  test "public pages" do
    %w[/ /about /contact].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
    end
  end

  test "signed-in users land on the blog" do
    sign_in users(:alice)
    get root_path
    assert_select "h1", "Blog"
  end

  test "profile and settings require sign-in" do
    get profile_path
    assert_redirected_to new_user_session_path

    sign_in users(:alice)
    get profile_path
    assert_response :success
    assert_select "h1", "alice"

    get settings_path
    assert_response :success
  end

  test "health check" do
    get rails_health_check_path
    assert_response :success
  end
end
