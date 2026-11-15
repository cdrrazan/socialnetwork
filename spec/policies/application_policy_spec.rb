require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:record) { create(:post, user: user) }

  permissions :index?, :show?, :create?, :new?, :update?, :edit?, :destroy? do
    it "denies everything by default, even to the owner" do
      expect(subject).not_to permit(user, record)
    end
  end

  describe ApplicationPolicy::Scope do
    it "returns every record by default" do
      create_list(:post, 2)
      expect(described_class.new(user, Post).resolve).to match_array(Post.all)
    end
  end

  describe "ownership helpers" do
    let(:policy_class) do
      Class.new(ApplicationPolicy) do
        public :signed_in?, :admin?, :owner?, :owner_or_admin?
      end
    end

    it "treats a nil user as signed out and not an admin" do
      policy = policy_class.new(nil, record)
      expect(policy).to have_attributes(signed_in?: false, admin?: false, owner?: false, owner_or_admin?: false)
    end

    it "recognises the owner" do
      expect(policy_class.new(user, record)).to have_attributes(owner?: true, owner_or_admin?: true)
    end

    it "recognises a moderator" do
      expect(policy_class.new(create(:user, :moderator), record)).to have_attributes(admin?: true, owner_or_admin?: true)
    end

    it "never treats records without a user_id as owned" do
      expect(policy_class.new(user, Object.new).owner?).to be(false)
    end
  end
end
