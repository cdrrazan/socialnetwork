require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
  test "only the author may edit; moderators may also delete" do
    comment = comments(:bobs_comment)

    assert CommentPolicy.new(users(:bob), comment).update?
    assert_not CommentPolicy.new(users(:moderator), comment).update?
    assert CommentPolicy.new(users(:moderator), comment).destroy?
    assert_not CommentPolicy.new(users(:alice), comment).destroy?
  end
end
