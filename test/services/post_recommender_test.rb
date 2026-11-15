require "test_helper"

class PostRecommenderTest < ActiveSupport::TestCase
  test "ranks posts by textual similarity and excludes the post itself" do
    similar = PostRecommender.new(posts(:rails)).similar

    assert_equal posts(:ruby), similar.first
    assert_not_includes similar, posts(:rails)
  end

  test "ignores posts with nothing in common" do
    assert_not_includes PostRecommender.new(posts(:rails)).similar, posts(:cooking)
  end

  test "does not recommend unpublished posts" do
    assert_not_includes PostRecommender.new(posts(:rails)).similar, posts(:draft)
  end

  test "respects the limit" do
    assert_operator PostRecommender.new(posts(:rails)).similar(limit: 1).size, :<=, 1
  end

  test "returns nothing when there is no other post" do
    Post.where.not(id: posts(:rails).id).delete_all
    assert_empty PostRecommender.new(posts(:rails)).similar
  end
end
