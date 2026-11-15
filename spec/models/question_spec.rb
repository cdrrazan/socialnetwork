require "rails_helper"

RSpec.describe Question do
  subject(:question) { build(:question) }

  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:answers).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_length_of(:title).is_at_most(255) }
  it { is_expected.to validate_length_of(:body).is_at_most(65_535) }

  describe ".newest_first" do
    it "orders newest first" do
      old = create(:question, created_at: 1.week.ago)
      recent = create(:question)
      expect(described_class.newest_first).to eq([ recent, old ])
    end
  end

  describe "#to_param" do
    it "includes a slug of the title" do
      question = create(:question, title: "Why is Ruby fun?")
      expect(question.to_param).to eq("#{question.id}-why-is-ruby-fun")
    end
  end

  describe "answers_count" do
    it "tracks the number of answers" do
      question = create(:question)
      create_list(:answer, 2, question: question)
      expect(question.reload.answers_count).to eq(2)

      question.answers.first.destroy!
      expect(question.reload.answers_count).to eq(1)
    end
  end

  it "exposes only safe attributes to admin search" do
    expect(described_class.ransackable_attributes).to eq(%w[id title body created_at])
    expect(described_class.ransackable_associations).to eq([])
  end
end
