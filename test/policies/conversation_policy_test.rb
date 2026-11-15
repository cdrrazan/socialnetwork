require "test_helper"

class ConversationPolicyTest < ActiveSupport::TestCase
  test "only participants may view a conversation" do
    conversation = conversations(:alice_and_bob)

    assert ConversationPolicy.new(users(:bob), conversation).show?
    assert_not ConversationPolicy.new(users(:carol), conversation).show?
  end
end
