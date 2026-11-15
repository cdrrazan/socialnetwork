require "rails_helper"

RSpec.describe PostPolicy do
  subject { described_class }

  let(:author) { create(:user) }
  let(:member) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let(:post) { create(:post, user: author) }
  let(:draft) { create(:post, :draft, user: author) }

  permissions :index?, :create?, :new? do
    it { is_expected.to permit(member, Post) }
    it { is_expected.not_to permit(nil, Post) }
  end

  permissions :show?, :vote? do
    it { is_expected.to permit(member, post) }
    it { is_expected.not_to permit(nil, post) }

    it "hides drafts from other members" do
      expect(subject).not_to permit(member, draft)
    end

    it "shows drafts to their author and moderators" do
      expect(subject).to permit(author, draft)
      expect(subject).to permit(moderator, draft)
    end
  end

  permissions :update?, :edit?, :destroy? do
    it { is_expected.to permit(author, post) }
    it { is_expected.to permit(moderator, post) }
    it { is_expected.not_to permit(member, post) }
    it { is_expected.not_to permit(nil, post) }
  end

  describe PostPolicy::Scope do
    it "returns published posts only" do
      post
      draft
      expect(described_class.new(member, Post).resolve).to contain_exactly(post)
    end
  end
end
