require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a unique, well-formed username" do
    user = User.new(email: "new@example.com", password: "password", username: "ALICE")
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"

    user.username = "not valid!"
    assert_not user.valid?
    assert user.errors[:username].any?

    user.username = "new_user"
    assert user.valid?
  end

  test "sets the permalink from the username" do
    user = User.create!(email: "dev@example.com", password: "password", username: "DevPerson")
    assert_equal "devperson", user.permalink
  end

  test "search matches username or email and escapes LIKE wildcards" do
    assert_equal [ users(:alice) ], User.search("alic").to_a
    assert_equal [ users(:bob) ], User.search("bob@example").to_a
    assert_empty User.search("%")
    assert_equal User.count, User.search("").count
  end

  test "following?" do
    assert users(:alice).following?(users(:bob))
    assert_not users(:bob).following?(users(:alice))
  end

  test "friends and inverse friends" do
    assert_includes users(:alice).friends, users(:bob)
    assert_includes users(:bob).inverse_friends, users(:alice)
  end

  test "rejects non-image avatars" do
    user = users(:alice)
    user.avatar.attach(io: StringIO.new("not an image"), filename: "notes.txt", content_type: "text/plain")
    assert_not user.valid?
    assert_includes user.errors[:avatar], "must be an image"
  end

  test "destroying a user removes their content" do
    assert_difference -> { Post.count } => -2, -> { Friendship.count } => -1 do
      users(:alice).destroy
    end
  end

  test "display_name falls back to email" do
    assert_equal "alice", users(:alice).display_name
    assert_equal "x@example.com", User.new(email: "x@example.com").display_name
  end
end
