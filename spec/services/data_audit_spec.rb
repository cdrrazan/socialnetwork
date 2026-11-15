require "rails_helper"

RSpec.describe DataAudit, :legacy_tables do
  subject(:audit) { described_class.new }

  def checks
    audit.problems.map(&:check)
  end

  def problem(check)
    audit.problems.find { |p| p.check == check }
  end

  context "with clean data" do
    before do
      post = create(:post)
      create(:comment, post: post)
      create(:answer)
      create(:friendship)
      create(:conversation, :with_messages)
    end

    it "finds nothing" do
      expect(audit).to be_clean
      expect(audit.problems).to be_empty
      expect(audit.report).to eq("No problems found.")
    end
  end

  describe "missing required values" do
    it "reports NULL columns in a 2017-style table" do
      with_legacy_table(:comments, id: "bigint", body: "text", user_id: "bigint", post_id: "bigint") do
        legacy_insert(:comments, [
          { id: 1, body: nil, user_id: nil, post_id: nil },
          { id: 2, body: nil, user_id: nil, post_id: nil },
          { id: 3, body: "fine", user_id: nil, post_id: nil }
        ])

        expect(problem(:missing_value)).to have_attributes(description: "comments.body is empty", count: 2, sample_ids: [ 1, 2 ])
        expect(audit.problems.map(&:description)).to include("comments.user_id is empty", "comments.post_id is empty")
      end
    end

    it "skips columns the table doesn't have yet" do
      with_legacy_table(:questions, id: "bigint", title: "varchar(255)") do
        legacy_insert(:questions, { id: 1, title: nil })
        expect(audit.problems.map(&:description)).to eq([ "questions.title is empty" ])
      end
    end
  end

  describe "orphaned rows" do
    it "reports rows pointing at deleted parents" do
      user = create(:user)
      with_legacy_table(:answers, id: "bigint", body: "text", user_id: "bigint", question_id: "bigint") do
        legacy_insert(:answers, [
          { id: 7, body: "lost", user_id: user.id, question_id: 999_999 },
          { id: 8, body: "fine", user_id: user.id, question_id: nil }
        ])

        expect(problem(:orphan)).to have_attributes(
          description: "answers.question_id points to a missing question", count: 1, sample_ids: [ 7 ]
        )
      end
    end

    it "limits samples to five ids" do
      with_legacy_table(:friendships, id: "bigint", user_id: "bigint", friend_id: "bigint") do
        legacy_insert(:friendships, (1..7).map { |id| { id: id, user_id: 0, friend_id: 0 } })

        orphan = audit.problems.find { |p| p.description == "friendships.user_id points to a missing user" }
        expect(orphan.count).to eq(7)
        expect(orphan.sample_ids).to eq([ 1, 2, 3, 4, 5 ])
      end
    end
  end

  describe "usernames" do
    it "reports missing, invalid and duplicate usernames" do
      with_legacy_table(:users, id: "bigint", username: "varchar(255)") do
        legacy_insert(:users, [
          { id: 1, username: nil },
          { id: 2, username: "" },
          { id: 3, username: "has space" },
          { id: 4, username: "Alice" },
          { id: 5, username: "alice" },
          { id: 6, username: "bob" }
        ])

        expect(problem(:missing_username)).to have_attributes(count: 2, sample_ids: [ 1, 2 ])
        expect(problem(:invalid_username)).to have_attributes(count: 1, sample_ids: [ 3 ])
        expect(problem(:duplicate_username)).to have_attributes(count: 2, sample_ids: [ 4, 5 ])
      end
    end

    it "skips username checks on databases that predate usernames" do
      with_legacy_table(:users, id: "bigint", email: "varchar(255)") do
        legacy_insert(:users, { id: 1, email: "old@example.com" })
        expect(checks).not_to include(:missing_username, :invalid_username, :duplicate_username)
      end
    end
  end

  describe "self references and duplicates" do
    it "reports self-follows and duplicate follows" do
      user = create(:user)
      friend = create(:user)
      with_legacy_table(:friendships, id: "bigint", user_id: "bigint", friend_id: "bigint") do
        legacy_insert(:friendships, [
          { id: 1, user_id: user.id, friend_id: user.id },
          { id: 2, user_id: user.id, friend_id: friend.id },
          { id: 3, user_id: user.id, friend_id: friend.id },
          { id: 4, user_id: user.id, friend_id: friend.id }
        ])

        expect(problem(:self_follow)).to have_attributes(count: 1, sample_ids: [ 1 ])
        expect(problem(:duplicate_friendship)).to have_attributes(count: 2, sample_ids: [])
      end
    end

    it "reports conversations with yourself" do
      user = create(:user)
      with_legacy_table(:conversations, id: "bigint", author_id: "bigint", receiver_id: "bigint") do
        legacy_insert(:conversations, { id: 9, author_id: user.id, receiver_id: user.id })
        expect(problem(:self_conversation)).to have_attributes(count: 1, sample_ids: [ 9 ])
      end
    end
  end

  describe "post states" do
    it "reports states other than published and unpublished" do
      with_legacy_table(:posts, id: "bigint", state: "varchar(255)") do
        legacy_insert(:posts, [ { id: 1, state: "archived" }, { id: 2, state: nil }, { id: 3, state: "published" } ])
        expect(problem(:invalid_state)).to have_attributes(count: 1, sample_ids: [ 1 ])
      end
    end
  end

  describe "counter caches" do
    it "reports drifted comment and answer counts" do
      post = create(:post)
      create(:comment, post: post)
      post.update_columns(comments_count: 5)
      question = create(:question)
      question.update_columns(answers_count: 3)

      expect(audit.problems.map(&:description)).to contain_exactly(
        "posts.comments_count out of date (fix with bin/rails data:reset_counters)",
        "questions.answers_count out of date (fix with bin/rails data:reset_counters)"
      )
    end

    it "is skipped before the counter cache columns exist" do
      with_legacy_table(:posts, id: "bigint", title: "varchar(255)") do
        expect(checks).not_to include(:counter_drift)
      end
    end
  end

  describe "#report" do
    it "lists every problem with sample ids" do
      post = create(:post)
      post.update_columns(comments_count: 2)

      expect(audit.report).to eq(<<~REPORT.chomp)
        Found 1 problem(s):
        - posts.comments_count out of date (fix with bin/rails data:reset_counters): 1 (e.g. ids #{post.id})
      REPORT
    end
  end

  describe DataAudit::Problem do
    it "omits the sample list when there are no sample ids" do
      problem = described_class.new(check: :x, description: "duplicate follows", count: 3, sample_ids: [])
      expect(problem.to_s).to eq("duplicate follows: 3")
    end
  end

  describe ".reset_counters!" do
    it "recalculates comment, answer and vote counters" do
      post = create(:post)
      create_list(:comment, 2, post: post)
      post.upvote_from(create(:user))
      post.update_columns(comments_count: 0, cached_votes_up: 0, cached_votes_total: 0, cached_votes_score: 0)
      question = create(:question)
      create(:answer, question: question)
      question.update_columns(answers_count: 9)

      expect(described_class.reset_counters!).to eq(2)

      expect(post.reload).to have_attributes(comments_count: 2, cached_votes_up: 1, cached_votes_total: 1, cached_votes_score: 1)
      expect(question.reload.answers_count).to eq(1)
      expect(described_class.new).to be_clean
    end
  end
end
