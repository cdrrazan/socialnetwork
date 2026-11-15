require "test_helper"

class PostPolicyTest < ActiveSupport::TestCase
  test "owners and moderators may change a post" do
    post = posts(:rails)

    assert PostPolicy.new(users(:alice), post).update?
    assert PostPolicy.new(users(:moderator), post).destroy?
    assert_not PostPolicy.new(users(:bob), post).update?
    assert_not PostPolicy.new(users(:bob), post).destroy?
    assert_not PostPolicy.new(nil, post).show?
  end

  test "scope only returns published posts" do
    scope = PostPolicy::Scope.new(users(:alice), Post).resolve
    assert_not_includes scope, posts(:draft)
  end
end
