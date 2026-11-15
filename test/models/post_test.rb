require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "requires a title and body" do
    post = Post.new(user: users(:alice))
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
    assert_includes post.errors[:body], "can't be blank"
  end

  test "published scope excludes drafts" do
    assert_includes Post.published, posts(:rails)
    assert_not_includes Post.published, posts(:draft)
    assert_includes Post.unpublished, posts(:draft)
  end

  test "publish!" do
    posts(:draft).publish!
    assert_includes Post.published, posts(:draft).reload
  end

  test "to_param includes a slug" do
    assert_equal "#{posts(:rails).id}-getting-started-with-rails", posts(:rails).to_param
  end

  test "tags" do
    post = posts(:rails)
    post.update!(tag_list: "ruby, rails")
    assert_equal %w[rails ruby], post.reload.tag_list.sort
    assert_includes Post.tagged_with("ruby"), post
  end

  test "votes" do
    post = posts(:rails)
    post.upvote_from users(:bob)
    post.downvote_from users(:carol)
    assert_equal 1, post.get_upvotes.size
    assert_equal 1, post.get_downvotes.size
  end
end
