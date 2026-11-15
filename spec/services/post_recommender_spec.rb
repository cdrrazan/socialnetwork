require "rails_helper"

RSpec.describe PostRecommender do
  let!(:rails_intro) do
    create(:post, title: "Rails intro", body: "<p>Rails is a web framework written in Ruby. Rails makes web apps fun.</p>")
  end
  let!(:ruby_post) do
    create(:post, title: "Ruby", body: "<p>Ruby is a friendly language. Many web apps use Ruby and Rails.</p>")
  end
  let!(:web_post) do
    create(:post, title: "The web", body: "<p>Building for the web means HTTP, HTML and apps.</p>")
  end
  let!(:cooking) do
    create(:post, title: "Momo", body: "<p>Steam the dumplings and serve with tomato achar.</p>")
  end

  def similar(post, **options)
    described_class.new(post, **options.slice(:scope)).similar(**options.except(:scope))
  end

  it "ranks the most similar post first" do
    expect(similar(rails_intro).first).to eq(ruby_post)
  end

  it "orders results by descending similarity" do
    expect(similar(rails_intro).to_a).to eq([ ruby_post, web_post ])
  end

  it "never recommends the post itself" do
    expect(similar(rails_intro)).not_to include(rails_intro)
  end

  it "leaves out posts with nothing in common" do
    expect(similar(rails_intro)).not_to include(cooking)
    expect(similar(cooking)).to be_empty
  end

  it "ignores HTML markup when comparing" do
    tagged = create(:post, body: "<strong>dumplings</strong> <em>achar</em> <p>steam</p>")
    expect(similar(cooking)).to contain_exactly(tagged)
  end

  it "skips unpublished drafts" do
    draft = create(:post, :draft, body: rails_intro.body)
    expect(similar(rails_intro)).not_to include(draft)
  end

  it "honours the limit" do
    expect(similar(rails_intro, limit: 1).to_a).to eq([ ruby_post ])
  end

  it "accepts a custom scope" do
    scope = Post.where(user: web_post.user)
    expect(similar(rails_intro, scope: scope).to_a).to eq([ web_post ])
  end

  it "returns an empty relation when there are no other posts" do
    Post.where.not(id: rails_intro.id).destroy_all
    result = similar(rails_intro)
    expect(result).to be_a(ActiveRecord::Relation)
    expect(result).to be_empty
  end

  it "works for a post that hasn't been saved yet" do
    draft = build(:post, body: "Ruby and Rails")
    expect(similar(draft)).to include(ruby_post, rails_intro)
  end

  it "ignores common English words" do
    unrelated = create(:post, body: "<p>The cat sat with the dog and the bird.</p>")
    expect(similar(cooking)).not_to include(unrelated)
  end

  it "matches words regardless of case" do
    shouting = create(:post, body: "<p>DUMPLINGS AND ACHAR</p>")
    expect(similar(cooking)).to include(shouting)
  end

  it "loads the corpus with a single query" do
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      described_class.new(rails_intro).similar.load
    end
    expect(queries.size).to eq(2) # one pluck for the corpus, one to load the results
  end
end
