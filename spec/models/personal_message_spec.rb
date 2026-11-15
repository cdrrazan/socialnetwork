require "rails_helper"

RSpec.describe PersonalMessage do
  subject { build(:personal_message) }

  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:conversation).touch(true) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_length_of(:body).is_at_most(5_000) }

  it "bumps the conversation's updated_at so it moves to the top of the inbox" do
    conversation = create(:conversation)
    conversation.update_columns(updated_at: 1.week.ago)

    create(:personal_message, conversation: conversation)

    expect(conversation.reload.updated_at).to be_within(1.minute).of(Time.current)
  end
end
