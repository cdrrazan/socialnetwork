require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup { @conversation = conversations(:alice_and_bob) }

  test "participants see their conversations" do
    sign_in users(:bob)
    get conversations_path
    assert_select "#conversation_#{@conversation.id}"

    get conversation_path(@conversation)
    assert_response :success
    assert_select "#conversation-body, .conversation-body", /Hi Bob!/
  end

  test "outsiders are turned away" do
    sign_in users(:carol)
    get conversation_path(@conversation)
    assert_redirected_to root_path
  end
end
