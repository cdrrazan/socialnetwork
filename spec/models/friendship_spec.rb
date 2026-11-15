require "rails_helper"

RSpec.describe Friendship do
  subject(:friendship) { build(:friendship) }

  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:friend).class_name("User") }

  it "doesn't allow following the same person twice" do
    existing = create(:friendship)
    duplicate = build(:friendship, user: existing.user, friend: existing.friend)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:friend_id]).to include("has already been taken")
  end

  it "allows following each other" do
    existing = create(:friendship)
    expect(build(:friendship, user: existing.friend, friend: existing.user)).to be_valid
  end

  it "doesn't allow following yourself" do
    user = create(:user)
    friendship = build(:friendship, user: user, friend: user)

    expect(friendship).not_to be_valid
    expect(friendship.errors[:friend]).to include("can't be yourself")
  end
end
