require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  setup { @conversation = conversations(:alice_and_bob) }

  test "with returns the other participant" do
    assert_equal users(:bob), @conversation.with(users(:alice))
    assert_equal users(:alice), @conversation.with(users(:bob))
  end

  test "participates?" do
    assert @conversation.participates?(users(:alice))
    assert_not @conversation.participates?(users(:carol))
  end

  test "between finds the conversation in either direction" do
    assert_equal [ @conversation ], Conversation.between(users(:bob).id, users(:alice).id).to_a
  end

  test "participating" do
    assert_includes Conversation.participating(users(:bob)), @conversation
    assert_empty Conversation.participating(users(:carol))
  end

  test "only one conversation per pair" do
    assert_not Conversation.new(author: users(:alice), receiver: users(:bob)).valid?
  end

  test "new messages bump updated_at" do
    @conversation.update_columns(updated_at: 1.week.ago)
    @conversation.personal_messages.create!(user: users(:bob), body: "Hey")
    assert_in_delta Time.current, @conversation.reload.updated_at, 5.seconds
  end
end
