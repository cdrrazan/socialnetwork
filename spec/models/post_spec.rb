require "rails_helper"

RSpec.describe Post do
  subject(:post) { build(:post) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }
    it { is_expected.to validate_length_of(:body).is_at_most(65_535) }
    it { is_expected.to validate_inclusion_of(:state).in_array(Post::STATES).allow_nil }
  end

  describe "scopes" do
    let!(:member_post) { create(:post, created_at: 2.days.ago) }
    let!(:published) { create(:post, :explicitly_published, created_at: 1.day.ago) }
    let!(:draft) { create(:post, :draft) }

    it ".published includes posts without a state and published posts" do
      expect(described_class.published).to contain_exactly(member_post, published)
    end

    it ".unpublished returns drafts only" do
      expect(described_class.unpublished).to contain_exactly(draft)
    end

    it ".newest_first orders by creation time, newest first" do
      expect(described_class.newest_first.first(3)).to eq([ draft, published, member_post ])
    end

    it ".top_rated orders by net votes, then recency" do
      voter = create(:user)
      member_post.upvote_from(voter)
      published.downvote_from(voter)

      expect(described_class.top_rated.first).to eq(member_post)
      expect(described_class.top_rated.last).to eq(published)
    end
  end

  describe "#publish!" do
    it "publishes a draft" do
      draft = create(:post, :draft)
      draft.publish!
      expect(draft.reload).to be_published
      expect(described_class.published).to include(draft)
    end
  end

  describe "#published?" do
    it { expect(build(:post)).to be_published }
    it { expect(build(:post, :explicitly_published)).to be_published }
    it { expect(build(:post, :draft)).not_to be_published }
  end

  describe "#to_param" do
    it "combines the id with a slug of the title" do
      post = create(:post, title: "Hello, Rails 8!")
      expect(post.to_param).to eq("#{post.id}-hello-rails-8")
    end

    it "can be used to find the post again" do
      post = create(:post)
      expect(described_class.find(post.to_param)).to eq(post)
    end
  end

  describe "tags" do
    it "stores tags lowercase and without duplicates" do
      post = create(:post, tag_list: "Ruby, rails, RUBY")
      expect(post.reload.tag_list).to contain_exactly("ruby", "rails")
    end

    it "can be queried by tag" do
      tagged = create(:post, :tagged)
      create(:post, tag_list: "cooking")
      expect(described_class.tagged_with("rails")).to contain_exactly(tagged)
    end

    it "caches the tag list on the post so listing posts needs no tag queries" do
      post = create(:post, tag_list: "ruby, rails")
      expect(post.reload.cached_tag_list).to eq("ruby, rails")

      expect { described_class.includes(:taggings).find(post.id).tag_list }
        .not_to make_database_queries(matching: /FROM `tags`/)
    end

    it "removes tags no post uses any more" do
      post = create(:post, tag_list: "lonely")
      post.update!(tag_list: "")
      expect(ActsAsTaggableOn::Tag.where(name: "lonely")).not_to exist
    end
  end

  describe "votes" do
    let(:post) { create(:post) }
    let(:voters) { create_list(:user, 3) }

    it "keeps the cached vote columns in sync" do
      post.upvote_from(voters[0])
      post.upvote_from(voters[1])
      post.downvote_from(voters[2])

      post.reload
      expect(post.cached_votes_up).to eq(2)
      expect(post.cached_votes_down).to eq(1)
      expect(post.cached_votes_total).to eq(3)
      expect(post.cached_votes_score).to eq(1)
    end

    it "lets a voter change their mind" do
      post.upvote_from(voters[0])
      post.downvote_from(voters[0])

      expect(post.reload.cached_votes_up).to eq(0)
      expect(post.cached_votes_down).to eq(1)
    end
  end

  describe "comments_count" do
    it "is maintained as comments come and go" do
      post = create(:post)
      comment = create(:comment, post: post)
      create(:comment, post: post)
      expect(post.reload.comments_count).to eq(2)

      comment.destroy!
      expect(post.reload.comments_count).to eq(1)
    end
  end

  describe "#similar_posts" do
    it "delegates to PostRecommender" do
      post = build(:post)
      recommender = instance_double(PostRecommender, similar: [ :result ])
      allow(PostRecommender).to receive(:new).with(post).and_return(recommender)

      expect(post.similar_posts(limit: 3)).to eq([ :result ])
      expect(recommender).to have_received(:similar).with(limit: 3)
    end
  end

  describe "activity tracking" do
    it "can record a public activity" do
      post = create(:post)
      expect { post.create_activity(:create, owner: post.user) }
        .to change(PublicActivity::Activity, :count).by(1)
      expect(PublicActivity::Activity.last).to have_attributes(key: "post.create", owner: post.user, trackable: post)
    end
  end

  describe ".ransackable_attributes" do
    it "lists the searchable columns" do
      expect(described_class.ransackable_attributes).to eq(%w[id title body state created_at updated_at])
      expect(described_class.ransackable_associations).to eq([])
    end
  end
end
