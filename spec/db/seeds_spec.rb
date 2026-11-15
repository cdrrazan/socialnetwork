require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def load_seeds
    expect { load Rails.root.join("db/seeds.rb") }.to output.to_stdout
  end

  it "creates demo members, content and an admin" do
    load_seeds

    expect(User.pluck(:username)).to contain_exactly("code", "world", "rubynepal")
    expect(AdminUser.pluck(:email)).to eq([ "admin@example.com" ])
    expect(Post.count).to eq(5)
    expect(Question.count).to eq(3)
    expect(PublicActivity::Activity.count).to be_positive
    expect(DataAudit.new).to be_clean
  end

  it "can be run repeatedly without duplicating anything" do
    load_seeds
    counts = [ User, Post, Comment, Question, Answer, Friendship, Conversation, PersonalMessage, PublicActivity::Activity ].map(&:count)

    load_seeds

    expect([ User, Post, Comment, Question, Answer, Friendship, Conversation, PersonalMessage, PublicActivity::Activity ].map(&:count))
      .to eq(counts)
  end

  context "in production" do
    before { allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new("production")) }

    it "refuses to create accounts with well-known passwords" do
      expect { load Rails.root.join("db/seeds.rb") }.to output(/Skipping demo seed data/).to_stdout
      expect(User.count).to eq(0)
      expect(AdminUser.count).to eq(0)
    end

    it "loads the demo data when explicitly asked to" do
      stub_const("ENV", ENV.to_h.merge("SEED_DEMO_DATA" => "true"))
      load_seeds
      expect(User.count).to eq(3)
    end
  end
end
