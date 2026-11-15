require "test_helper"

class FriendshipsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:alice) }

  test "follow" do
    assert_difference("users(:alice).friends.count") do
      post friendships_path(friend_id: users(:carol).id)
    end
    assert users(:alice).following?(users(:carol))
  end

  test "following twice fails gracefully" do
    assert_no_difference("Friendship.count") do
      post friendships_path(friend_id: users(:bob).id)
    end
    assert_predicate flash[:alert], :present?
  end

  test "unfollow" do
    assert_difference("Friendship.count", -1) do
      delete friendship_path(users(:bob))
    end
    assert_not users(:alice).following?(users(:bob))
  end
end
