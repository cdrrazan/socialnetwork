require "rails_helper"

RSpec.describe AnswerPolicy do
  subject { described_class }

  let(:author) { create(:user) }
  let(:member) { create(:user) }
  let(:answer) { create(:answer, user: author) }

  permissions :create?, :new? do
    it { is_expected.to permit(member, Answer.new) }
    it { is_expected.not_to permit(nil, Answer.new) }
  end

  permissions :destroy? do
    it { is_expected.to permit(author, answer) }
    it { is_expected.to permit(create(:user, :moderator), answer) }
    it { is_expected.not_to permit(member, answer) }
  end

  permissions :update?, :edit? do
    it "can't be edited, even by its author" do
      expect(subject).not_to permit(author, answer)
    end
  end
end
