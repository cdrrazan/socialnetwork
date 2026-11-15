require "rails_helper"

RSpec.describe Comment do
  subject { build(:comment) }

  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:post).counter_cache(true) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:body) }
  it { is_expected.to validate_length_of(:body).is_at_most(10_000) }

  describe ".chronological" do
    it "orders oldest first" do
      post = create(:post)
      newer = create(:comment, post: post, created_at: 1.minute.ago)
      older = create(:comment, post: post, created_at: 1.hour.ago)
      expect(post.comments.chronological).to eq([ older, newer ])
    end
  end

  it "can record a public activity" do
    comment = create(:comment)
    expect { comment.create_activity(:create, owner: comment.user) }
      .to change(PublicActivity::Activity, :count).by(1)
  end
end
