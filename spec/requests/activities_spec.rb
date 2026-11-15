require "rails_helper"

RSpec.describe "Activities" do
  let(:me) { create(:user) }
  let(:followed) { create(:user, username: "followed") }
  let(:stranger) { create(:user) }

  it "requires sign-in" do
    get activities_path
    expect(response).to redirect_to(new_user_session_path)
  end

  context "when signed in" do
    before do
      create(:friendship, user: me, friend: followed)
      sign_in me
    end

    it "shows what people you follow have done, newest first" do
      their_post = create(:post, user: followed, title: "Their post")
      their_post.create_activity(:create, owner: followed)
      comment = create(:comment, user: followed, post: create(:post, title: "Commented post"))
      comment.create_activity(:create, owner: followed)
      create(:post, user: stranger, title: "Stranger post").create_activity(:create, owner: stranger)

      get activities_path

      items = page_html.all("li.list-group-item").map(&:text).map(&:squish)
      expect(items.size).to eq(2)
      expect(items.first).to start_with("followed commented on Commented post")
      expect(items.last).to start_with("followed published Their post")
    end

    it "copes with content that has since been deleted" do
      gone_post = create(:post, user: followed)
      gone_post.create_activity(:create, owner: followed)
      gone_comment = create(:comment, user: followed)
      gone_comment.create_activity(:create, owner: followed)
      gone_comment.destroy!
      gone_post.destroy!

      get activities_path

      expect(page_html).to have_text("published a post that has since been removed")
      expect(page_html).to have_text("left a comment that has since been removed")
    end

    it "shows an empty state" do
      get activities_path
      expect(page_html).to have_text("Nothing here yet.")
    end

    it "shows at most 100 entries" do
      post = create(:post, user: followed)
      PublicActivity::Activity.insert_all(Array.new(105) do
        { trackable_type: "Post", trackable_id: post.id, owner_type: "User", owner_id: followed.id,
          key: "post.create", created_at: Time.current, updated_at: Time.current }
      end)

      get activities_path
      expect(page_html).to have_css("li.list-group-item", count: 100)
    end
  end
end
