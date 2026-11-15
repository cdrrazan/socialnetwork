require "rails_helper"

RSpec.describe ConversationPolicy do
  subject { described_class }

  let(:author) { create(:user) }
  let(:receiver) { create(:user) }
  let(:outsider) { create(:user) }
  let(:conversation) { create(:conversation, author: author, receiver: receiver) }

  permissions :index? do
    it { is_expected.to permit(outsider, Conversation) }
    it { is_expected.not_to permit(nil, Conversation) }
  end

  permissions :show? do
    it { is_expected.to permit(author, conversation) }
    it { is_expected.to permit(receiver, conversation) }
    it { is_expected.not_to permit(outsider, conversation) }

    it "isn't widened for moderators: messages are private" do
      expect(subject).not_to permit(create(:user, :moderator), conversation)
    end
  end

  describe ConversationPolicy::Scope do
    it "returns only the user's own conversations" do
      conversation
      other = create(:conversation, author: outsider, receiver: author)
      create(:conversation)

      expect(described_class.new(author, Conversation).resolve).to contain_exactly(conversation, other)
    end
  end
end
