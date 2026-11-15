require "rails_helper"

RSpec.describe Answer do
  subject { build(:answer) }

  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:question).counter_cache(true) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_length_of(:body).is_at_most(20_000) }

  describe ".chronological" do
    it "orders oldest first" do
      question = create(:question)
      newer = create(:answer, question: question, created_at: 1.minute.ago)
      older = create(:answer, question: question, created_at: 1.hour.ago)
      expect(question.answers.chronological).to eq([ older, newer ])
    end
  end

  it "exposes only safe attributes to admin search" do
    expect(described_class.ransackable_attributes).to eq(%w[id body created_at])
    expect(described_class.ransackable_associations).to eq([])
  end
end
