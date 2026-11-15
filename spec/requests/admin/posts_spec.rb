require "rails_helper"

RSpec.describe "Admin posts" do
  let(:admin) { create(:admin_user, email: "editor@example.com") }
  let!(:published) { create(:post, title: "Live post") }
  let!(:draft) { create(:post, :draft, title: "Draft post") }

  before { sign_in admin }

  describe "index" do
    it "lists posts with their state" do
      get admin_posts_path
      expect(page_html).to have_text("Live post")
      expect(page_html).to have_text("Draft post")
      expect(page_html).to have_css(".status_tag", text: /unpublished/i)
    end

    it "has published and unpublished scopes" do
      get admin_posts_path(scope: "unpublished")
      expect(page_html).to have_text("Draft post")
      expect(page_html).to have_no_text("Live post")

      get admin_posts_path(scope: "published")
      expect(page_html).to have_text("Live post")
      expect(page_html).to have_no_text("Draft post")
    end

    it "filters by title" do
      get admin_posts_path(q: { title_cont: "Draft" })
      expect(page_html).to have_text("Draft post")
      expect(page_html).to have_no_text("Live post")
    end

    it "refuses to filter on attributes outside the Ransack allowlist" do
      get admin_posts_path(q: { user_encrypted_password_cont: "x" })
      expect(page_html).to have_text("Live post") # the unknown condition is ignored
    end
  end

  describe "show" do
    it "renders the sanitized body and a publish button for drafts" do
      draft.update!(body: "<p>Hello</p><script>alert(1)</script>")
      get admin_post_path(draft)

      expect(page_html).to have_text("Hello")
      expect(response.body).not_to include("<script>alert(1)")
      expect(page_html).to have_link("Publish", href: publish_admin_post_path(draft))
    end

    it "doesn't offer to publish a published post" do
      get admin_post_path(published)
      expect(page_html).to have_no_link("Publish", exact: true)
    end
  end

  describe "creating" do
    it "drafts the post as unpublished, attributed to the matching member" do
      member = create(:user, email: "editor@example.com")

      expect { post admin_posts_path, params: { post: { title: "Announcement", body: "Big news" } } }
        .to change(Post, :count).by(1)

      created = Post.order(:id).last
      expect(created).to have_attributes(title: "Announcement", state: "unpublished", user: member)
      expect(response).to redirect_to(admin_post_path(created))
    end

    it "falls back to the first member when no member matches the admin's email" do
      first_member = User.order(:id).first
      post admin_posts_path, params: { post: { title: "Announcement", body: "Big news" } }
      expect(Post.order(:id).last.user).to eq(first_member)
    end

    it "renders the form" do
      get new_admin_post_path
      expect(page_html).to have_field("Title")
    end
  end

  describe "publishing" do
    it "publishes a single draft" do
      put publish_admin_post_path(draft)
      expect(draft.reload.state).to eq("published")
      expect(response).to redirect_to(admin_post_path(draft))
      expect(flash[:notice]).to eq("Post published.")
    end

    it "publishes several drafts with the batch action" do
      other = create(:post, :draft)
      post batch_action_admin_posts_path, params: { batch_action: "publish", collection_selection: [ draft.id, other.id ] }

      expect(Post.unpublished).to be_empty
      expect(flash[:notice]).to eq("2 post(s) published.")
    end
  end

  it "deletes a post" do
    expect { delete admin_post_path(published) }.to change(Post, :count).by(-1)
  end
end
