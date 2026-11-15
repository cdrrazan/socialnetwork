require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  test "admin pages require an admin login" do
    get admin_root_path
    assert_redirected_to new_admin_user_session_path
  end

  test "admin pages render" do
    sign_in admin_users(:admin)
    %w[/admin /admin/posts /admin/users /admin/questions /admin/answers /admin/admin_users].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
    end
  end

  test "filters work with the ransack allowlist" do
    sign_in admin_users(:admin)
    get admin_users_path(q: { email_cont: "alice" })
    assert_response :success
    assert_select "td", text: "alice@example.com"
  end

  test "publishing a draft" do
    sign_in admin_users(:admin)
    put publish_admin_post_path(posts(:draft))
    assert_equal "published", posts(:draft).reload.state
  end
end
