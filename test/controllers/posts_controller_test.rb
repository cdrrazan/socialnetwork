require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup { @post = posts(:rails) }

  test "requires sign-in" do
    get posts_path
    assert_redirected_to new_user_session_path
  end

  test "index lists published posts only" do
    sign_in users(:bob)
    get posts_path
    assert_response :success
    assert_select "h2", text: @post.title
    assert_select "h2", text: posts(:draft).title, count: 0
  end

  test "index filters by tag" do
    @post.update!(tag_list: "rails")
    sign_in users(:bob)
    get posts_path(tag: "rails")
    assert_select "h2", text: @post.title
    assert_select "h2", text: posts(:ruby).title, count: 0
  end

  test "show renders the post, comments and similar posts" do
    sign_in users(:bob)
    get post_path(@post)
    assert_response :success
    assert_select "h1", @post.title
    assert_select "#comments", /Great introduction!/
    assert_select "aside a", text: posts(:ruby).title
  end

  test "show sanitizes the body" do
    @post.update!(body: %(<p>Hi</p><script>alert("xss")</script>))
    sign_in users(:bob)
    get post_path(@post)
    assert_no_match "<script>alert", response.body
  end

  test "create" do
    sign_in users(:bob)
    assert_difference [ "Post.count", "PublicActivity::Activity.count" ], 1 do
      post posts_path, params: { post: { title: "New", body: "<p>Body</p>", tag_list: "ruby, testing" } }
    end
    created = Post.order(:id).last
    assert_redirected_to post_path(created)
    assert_equal users(:bob), created.user
    assert_equal %w[ruby testing], created.tag_list.sort
  end

  test "create with invalid params re-renders the form" do
    sign_in users(:bob)
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { title: "", body: "" } }
    end
    assert_response :unprocessable_content
  end

  test "owner can edit and update" do
    sign_in users(:alice)
    get edit_post_path(@post)
    assert_response :success

    patch post_path(@post), params: { post: { title: "Updated" } }
    assert_redirected_to post_path(@post.reload)
    assert_equal "Updated", @post.title
  end

  test "non-owners cannot update or delete" do
    sign_in users(:bob)
    patch post_path(@post), params: { post: { title: "Hacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hacked", @post.reload.title

    assert_no_difference("Post.count") { delete post_path(@post) }
  end

  test "moderators can delete any post" do
    sign_in users(:moderator)
    assert_difference("Post.count", -1) { delete post_path(@post) }
    assert_redirected_to posts_path
  end

  test "votes" do
    sign_in users(:bob)
    put like_post_path(@post)
    assert_equal 1, @post.get_upvotes.size

    put dislike_post_path(@post)
    assert_equal 0, @post.reload.get_upvotes.size
    assert_equal 1, @post.get_downvotes.size
  end
end
