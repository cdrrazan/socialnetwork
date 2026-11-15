require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:posts).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
    it { is_expected.to have_many(:questions).dependent(:destroy) }
    it { is_expected.to have_many(:answers).dependent(:destroy) }
    it { is_expected.to have_many(:personal_messages).dependent(:destroy) }
    it { is_expected.to have_many(:authored_conversations).class_name("Conversation").with_foreign_key(:author_id).dependent(:destroy) }
    it { is_expected.to have_many(:received_conversations).class_name("Conversation").with_foreign_key(:receiver_id).dependent(:destroy) }
    it { is_expected.to have_many(:friendships).dependent(:destroy) }
    it { is_expected.to have_many(:friends).through(:friendships) }
    it { is_expected.to have_many(:inverse_friendships).class_name("Friendship").with_foreign_key(:friend_id).dependent(:destroy) }
    it { is_expected.to have_many(:inverse_friends).through(:inverse_friendships).source(:user) }
    it { is_expected.to have_one_attached(:avatar) }
  end

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }

    it "accepts letters, numbers, underscores, dots and dashes in usernames" do
      %w[alice bob_99 jane.doe dev-ops].each do |name|
        user.username = name
        expect(user).to be_valid, "expected #{name.inspect} to be valid"
      end
    end

    it "rejects other characters in usernames" do
      [ "with space", "semi;colon", "émile", "bang!" ].each do |name|
        user.username = name
        expect(user).not_to be_valid, "expected #{name.inspect} to be invalid"
        expect(user.errors[:username]).to include("may only contain letters, numbers, _ . and -")
      end
    end

    it "requires the avatar to be an image" do
      user.avatar.attach(io: StringIO.new("plain text"), filename: "notes.txt", content_type: "text/plain")

      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("must be an image")
    end

    it "accepts an image avatar" do
      expect(build(:user, :with_avatar)).to be_valid
    end
  end

  describe "callbacks" do
    it "stores a lowercase permalink derived from the username" do
      user = create(:user, username: "DevPerson")
      expect(user.permalink).to eq("devperson")
    end

    it "leaves the permalink alone when there is no username" do
      user = create(:user, username: "first")
      user.username = nil
      user.save!(validate: false)
      expect(user.reload.permalink).to eq("first")
    end
  end

  describe ".search" do
    let!(:alice) { create(:user, username: "alice", email: "alice@example.com") }
    let!(:bob) { create(:user, username: "bob", email: "bob@sample.org") }

    it "returns everyone for a blank query" do
      expect(described_class.search("")).to contain_exactly(alice, bob)
      expect(described_class.search(nil)).to contain_exactly(alice, bob)
    end

    it "matches part of a username" do
      expect(described_class.search("lic")).to contain_exactly(alice)
    end

    it "matches part of an email address" do
      expect(described_class.search("sample.org")).to contain_exactly(bob)
    end

    it "is case-insensitive" do
      expect(described_class.search("ALICE")).to contain_exactly(alice)
    end

    it "treats LIKE wildcards literally" do
      expect(described_class.search("%")).to be_empty
      expect(described_class.search("_")).to be_empty
    end
  end

  describe ".alphabetical" do
    it "orders by username" do
      zed = create(:user, username: "zed")
      amy = create(:user, username: "amy")
      expect(described_class.alphabetical).to eq([ amy, zed ])
    end
  end

  describe "#following?" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    it "is true for people the user follows" do
      create(:friendship, user: follower, friend: followed)
      expect(follower.following?(followed)).to be(true)
    end

    it "is false otherwise, and isn't symmetric" do
      create(:friendship, user: follower, friend: followed)
      expect(followed.following?(follower)).to be(false)
    end
  end

  describe "#display_name" do
    it "prefers the username" do
      expect(build(:user, username: "alice").display_name).to eq("alice")
    end

    it "falls back to the email address" do
      expect(build(:user, username: nil, email: "x@example.com").display_name).to eq("x@example.com")
    end
  end

  describe "followers and following" do
    it "exposes both directions of a follow" do
      alice = create(:user)
      bob = create(:user)
      create(:friendship, user: alice, friend: bob)

      expect(alice.friends).to contain_exactly(bob)
      expect(bob.inverse_friends).to contain_exactly(alice)
    end
  end

  describe "destroying a user" do
    it "removes everything they created and every follow involving them" do
      user = create(:user)
      other = create(:user)
      post = create(:post, user: user)
      create(:comment, post: post, user: other)
      create(:comment, user: user)
      create(:answer, question: create(:question, user: user), user: other)
      create(:friendship, user: user, friend: other)
      create(:friendship, user: other, friend: user)
      create(:conversation, :with_messages, author: user, receiver: other)

      user.destroy!

      expect(Post.where(user_id: user.id)).to be_empty
      expect(Comment.where(user_id: user.id)).to be_empty
      expect(Question.where(user_id: user.id)).to be_empty
      expect(Friendship.where(user_id: user.id).or(Friendship.where(friend_id: user.id))).to be_empty
      expect(Conversation.participating(user)).to be_empty
    end
  end

  describe ".ransackable_attributes" do
    it "never exposes credentials to admin search" do
      expect(described_class.ransackable_attributes).not_to include("encrypted_password", "reset_password_token")
      expect(described_class.ransackable_associations).to eq([])
    end
  end
end
