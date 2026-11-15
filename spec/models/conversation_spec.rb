require "rails_helper"

RSpec.describe Conversation do
  let(:alice) { create(:user) }
  let(:bob) { create(:user) }
  let(:carol) { create(:user) }
  let!(:conversation) { create(:conversation, author: alice, receiver: bob) }

  describe "associations" do
    subject { conversation }

    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to belong_to(:receiver).class_name("User") }
    it { is_expected.to have_many(:personal_messages).dependent(:destroy) }
  end

  describe "validations" do
    it "allows one conversation per pair of people" do
      expect(build(:conversation, author: alice, receiver: bob)).not_to be_valid
    end

    it "doesn't allow a conversation with yourself" do
      solo = build(:conversation, author: alice, receiver: alice)
      expect(solo).not_to be_valid
      expect(solo.errors[:receiver]).to include("can't be yourself")
    end
  end

  describe "#with" do
    it "returns the other participant" do
      expect(conversation.with(alice)).to eq(bob)
      expect(conversation.with(bob)).to eq(alice)
    end
  end

  describe "#participates?" do
    it { expect(conversation.participates?(alice)).to be(true) }
    it { expect(conversation.participates?(bob)).to be(true) }
    it { expect(conversation.participates?(carol)).to be(false) }
  end

  describe ".between" do
    it "finds the conversation whichever way round the ids are given" do
      expect(described_class.between(alice.id, bob.id)).to contain_exactly(conversation)
      expect(described_class.between(bob.id, alice.id)).to contain_exactly(conversation)
      expect(described_class.between(alice.id, carol.id)).to be_empty
    end
  end

  describe ".participating" do
    it "returns conversations the user started or received" do
      other = create(:conversation, author: carol, receiver: alice)
      expect(described_class.participating(alice)).to contain_exactly(conversation, other)
      expect(described_class.participating(bob)).to contain_exactly(conversation)
    end
  end

  describe "messages" do
    it "are ordered oldest first" do
      later = create(:personal_message, conversation: conversation, created_at: 1.minute.ago)
      earlier = create(:personal_message, conversation: conversation, created_at: 1.hour.ago)
      expect(conversation.personal_messages).to eq([ earlier, later ])
    end
  end
end
