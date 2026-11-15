require "rails_helper"

RSpec.describe "Conversations" do
  let(:alice) { create(:user, username: "alice") }
  let(:bob) { create(:user, username: "bob") }
  let(:carol) { create(:user) }
  let!(:conversation) { create(:conversation, :with_messages, author: alice, receiver: bob) }

  it "requires sign-in" do
    get conversations_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "GET /conversations" do
    it "lists the member's conversations, most recently active first" do
      older = create(:conversation, author: carol, receiver: bob)
      older.update_columns(updated_at: 1.week.ago)
      create(:conversation, author: alice, receiver: carol) # not bob's

      sign_in bob
      get conversations_path

      ids = page_html.all(".list-group-item").map { |row| row[:id] }
      expect(ids).to eq([ "conversation_#{conversation.id}", "conversation_#{older.id}" ])
      expect(page_html.find("#conversation_#{conversation.id}")).to have_text("alice").and have_text("Hi there!")
    end

    it "shows an empty state" do
      sign_in carol
      get conversations_path
      expect(page_html).to have_text("No conversations yet.")
    end
  end

  describe "GET /conversations/:id" do
    it "shows the messages to a participant" do
      sign_in bob
      get conversation_path(conversation)
      expect(page_html).to have_css("h1", text: "Conversation with alice")
      expect(page_html.find(".conversation-body")).to have_text("Hello!").and have_text("Hi there!")
      expect(page_html).to have_css("[data-controller='scroll-bottom']")
    end

    it "turns outsiders away" do
      sign_in carol
      get conversation_path(conversation)
      expect(response).to redirect_to(root_path)
    end
  end
end
