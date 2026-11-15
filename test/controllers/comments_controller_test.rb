require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:rails)
    @comment = comments(:bobs_comment)
  end

  test "create" do
    sign_in users(:carol)
    assert_difference "@post.comments.count", 1 do
      post post_comments_path(@post), params: { comment: { body: "Nice!" } }
    end
    assert_redirected_to post_path(@post)
  end

  test "blank comments are rejected" do
    sign_in users(:carol)
    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: { comment: { body: "" } }
    end
    assert_equal "Your comment could not be saved: Body can't be blank.", flash[:alert]
  end

  test "author can edit" do
    sign_in users(:bob)
    get edit_post_comment_path(@post, @comment)
    assert_response :success

    patch post_comment_path(@post, @comment), params: { comment: { body: "Edited" } }
    assert_equal "Edited", @comment.reload.body
  end

  test "others cannot delete" do
    sign_in users(:carol)
    assert_no_difference("Comment.count") { delete post_comment_path(@post, @comment) }
  end

  test "author can delete" do
    sign_in users(:bob)
    assert_difference("Comment.count", -1) { delete post_comment_path(@post, @comment) }
  end
end
