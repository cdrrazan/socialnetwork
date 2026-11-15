require "test_helper"

class SignUpTest < ActionDispatch::IntegrationTest
  test "signing up with a username" do
    assert_difference("User.count") do
      post user_registration_path, params: { user: { username: "newbie", email: "newbie@example.com",
                                                     password: "password", password_confirmation: "password" } }
    end
    assert_equal "newbie", User.order(:id).last.username
  end

  test "updating the profile picture" do
    user = users(:alice)
    sign_in user
    put user_registration_path, params: {
      user: { username: "alice", email: user.email, current_password: "password",
              avatar: fixture_file_upload("avatar.png", "image/png") }
    }
    assert user.reload.avatar.attached?
  end
end
