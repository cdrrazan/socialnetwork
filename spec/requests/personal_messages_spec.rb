require "rails_helper"

RSpec.describe "Personal messages" do
  let(:alice) { create(:user, username: "alice") }
  let(:bob) { create(:user, username: "bob") }
  let(:carol) { create(:user) }

  it "requires sign-in" do
    get new_personal_message_path(receiver_id: bob.id)
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "starting a conversation" do
    before { sign_in alice }

    it "shows the new message form" do
      get new_personal_message_path(receiver_id: bob.id)
      expect(page_html).to have_css("h1", text: "New message to bob")
    end

    it "jumps to an existing conversation instead" do
      conversation = create(:conversation, author: bob, receiver: alice)
      get new_personal_message_path(receiver_id: bob.id)
      expect(response).to redirect_to(conversation_path(conversation))
    end

    it "creates the conversation together with the first message" do
      expect { post personal_messages_path, params: { receiver_id: bob.id, personal_message: { body: "Hi Bob" } } }
        .to change(Conversation, :count).by(1).and change(PersonalMessage, :count).by(1)

      conversation = Conversation.order(:id).last
      expect(conversation).to have_attributes(author: alice, receiver: bob)
      expect(conversation.personal_messages.last).to have_attributes(user: alice, body: "Hi Bob")
      expect(response).to redirect_to(conversation_path(conversation))
      expect(flash[:notice]).to eq("Your message was sent.")
    end

    it "creates nothing when the first message is blank" do
      expect { post personal_messages_path, params: { receiver_id: bob.id, personal_message: { body: "" } } }
        .not_to change(Conversation, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "won't start a conversation with yourself" do
      get new_personal_message_path(receiver_id: alice.id)
      expect(response).to redirect_to(users_path)
      expect(flash[:alert]).to eq("You can't message yourself.")
    end

    it "returns 404 for a missing receiver" do
      get new_personal_message_path(receiver_id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "replying" do
    let!(:conversation) { create(:conversation, author: alice, receiver: bob) }

    it "adds a message to the conversation" do
      sign_in bob
      expect { post personal_messages_path, params: { conversation_id: conversation.id, personal_message: { body: "Hey" } } }
        .to change(conversation.personal_messages, :count).by(1)
      expect(response).to redirect_to(conversation_path(conversation))
    end

    it "explains a blank reply" do
      sign_in bob
      post personal_messages_path, params: { conversation_id: conversation.id, personal_message: { body: "" } }
      expect(response).to redirect_to(conversation_path(conversation))
      expect(flash[:alert]).to eq("Message can't be blank.")
    end

    it "won't post into someone else's conversation" do
      sign_in carol
      expect { post personal_messages_path, params: { conversation_id: conversation.id, personal_message: { body: "Intruder" } } }
        .not_to change(PersonalMessage, :count)
      expect(response).to redirect_to(root_path)
    end

    it "returns 404 for a missing conversation" do
      sign_in bob
      post personal_messages_path, params: { conversation_id: 0, personal_message: { body: "x" } }
      expect(response).to have_http_status(:not_found)
    end
  end
end
