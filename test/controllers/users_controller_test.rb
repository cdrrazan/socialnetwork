require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "index excludes the current user and searches" do
    get users_path
    assert_response :success
    assert_select "#user_#{users(:bob).id}"
    assert_select "#user_#{users(:alice).id}", count: 0

    get users_path(search: "carol")
    assert_select "#user_#{users(:carol).id}"
    assert_select "#user_#{users(:bob).id}", count: 0
  end

  test "show" do
    get user_path(users(:bob))
    assert_response :success
    assert_select "h1", "bob"
    assert_select "h2", text: posts(:ruby).title
  end

  test "my_friends" do
    get my_friends_path
    assert_response :success
    assert_select "a", text: "bob"
  end
end
