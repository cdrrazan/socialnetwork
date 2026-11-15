require "rails_helper"

RSpec.describe "data rake tasks" do
  describe "data:audit" do
    it "reports a clean database and exits normally" do
      expect { run_task("data:audit") }.to output("No problems found.\n").to_stdout
    end

    it "lists problems and exits with status 1" do
      post = create(:post)
      post.update_columns(comments_count: 4)

      expect {
        expect { run_task("data:audit") }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      }.to output(/posts\.comments_count out of date/).to_stdout
    end
  end

  describe "data:reset_counters" do
    it "fixes drifted counters" do
      post = create(:post)
      create(:comment, post: post)
      post.update_columns(comments_count: 0)

      expect { run_task("data:reset_counters") }.to output("Reset counters on 1 record(s).\n").to_stdout
      expect(post.reload.comments_count).to eq(1)
    end
  end
end
