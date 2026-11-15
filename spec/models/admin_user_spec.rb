require "rails_helper"

RSpec.describe AdminUser do
  subject { build(:admin_user) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

  it "authenticates with its password" do
    admin = create(:admin_user, password: "s3cret-pass")
    expect(admin.valid_password?("s3cret-pass")).to be(true)
    expect(admin.valid_password?("wrong")).to be(false)
  end

  it "exposes only safe attributes to admin search" do
    expect(described_class.ransackable_attributes).to eq(%w[id email current_sign_in_at sign_in_count created_at])
    expect(described_class.ransackable_associations).to eq([])
  end
end
