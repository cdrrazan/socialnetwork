require "test_helper"

class PersonalMessagesControllerTest < ActionDispatch::IntegrationTest
  test "new redirects to an existing conversation" do
    sign_in users(:bob)
    get new_personal_message_path(receiver_id: users(:alice).id)
    assert_redirected_to conversation_path(conversations(:alice_and_bob))
  end

  test "starting a new conversation" do
    sign_in users(:carol)
    get new_personal_message_path(receiver_id: users(:alice).id)
    assert_response :success

    assert_difference [ "Conversation.count", "PersonalMessage.count" ], 1 do
      post personal_messages_path, params: { receiver_id: users(:alice).id, personal_message: { body: "Hello" } }
    end
    assert_redirected_to conversation_path(Conversation.order(:id).last)
  end

  test "replying in a conversation" do
    sign_in users(:bob)
    assert_difference("PersonalMessage.count") do
      post personal_messages_path, params: { conversation_id: conversations(:alice_and_bob).id,
                                             personal_message: { body: "Hi Alice" } }
    end
  end

  test "cannot post into someone else's conversation" do
    sign_in users(:carol)
    assert_no_difference("PersonalMessage.count") do
      post personal_messages_path, params: { conversation_id: conversations(:alice_and_bob).id,
                                             personal_message: { body: "Intruder" } }
    end
  end

  test "cannot message yourself" do
    sign_in users(:carol)
    get new_personal_message_path(receiver_id: users(:carol).id)
    assert_redirected_to users_path
  end
end
