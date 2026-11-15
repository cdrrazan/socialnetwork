require "test_helper"

class FriendshipTest < ActiveSupport::TestCase
  test "cannot follow the same person twice" do
    duplicate = Friendship.new(user: users(:alice), friend: users(:bob))
    assert_not duplicate.valid?
  end

  test "cannot follow yourself" do
    friendship = Friendship.new(user: users(:alice), friend: users(:alice))
    assert_not friendship.valid?
    assert_includes friendship.errors[:friend], "can't be yourself"
  end
end
