require "rails_helper"

RSpec.describe CommentPolicy do
  subject { described_class }

  let(:author) { create(:user) }
  let(:member) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let(:comment) { create(:comment, user: author) }

  permissions :create?, :new? do
    it { is_expected.to permit(member, Comment.new) }
    it { is_expected.not_to permit(nil, Comment.new) }
  end

  permissions :update?, :edit? do
    it { is_expected.to permit(author, comment) }

    it "doesn't let moderators put words in someone's mouth" do
      expect(subject).not_to permit(moderator, comment)
    end

    it { is_expected.not_to permit(member, comment) }
  end

  permissions :destroy? do
    it { is_expected.to permit(author, comment) }
    it { is_expected.to permit(moderator, comment) }
    it { is_expected.not_to permit(member, comment) }
  end
end
