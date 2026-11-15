require "rails_helper"

RSpec.describe QuestionPolicy do
  subject { described_class }

  let(:author) { create(:user) }
  let(:member) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let(:question) { create(:question, user: author) }

  permissions :index?, :show? do
    it "is open to everyone, signed in or not" do
      expect(subject).to permit(nil, question)
      expect(subject).to permit(member, question)
    end
  end

  permissions :create?, :new? do
    it { is_expected.to permit(member, Question) }
    it { is_expected.not_to permit(nil, Question) }
  end

  permissions :update?, :edit?, :destroy? do
    it { is_expected.to permit(author, question) }
    it { is_expected.to permit(moderator, question) }
    it { is_expected.not_to permit(member, question) }
    it { is_expected.not_to permit(nil, question) }
  end
end
