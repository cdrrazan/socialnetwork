require "rails_helper"

RSpec.describe "Posts" do
  let(:author) { create(:user) }
  let(:member) { create(:user) }
  let(:moderator) { create(:user, :moderator) }
  let!(:post_record) { create(:post, user: author, title: "Getting started with Rails", tag_list: "rails") }

  describe "authentication" do
    it "redirects visitors to the login page" do
      [
        -> { get posts_path },
        -> { get post_path(post_record) },
        -> { get new_post_path },
        -> { post posts_path, params: { post: { title: "x", body: "y" } } },
        -> { put like_post_path(post_record) }
      ].each do |request|
        instance_exec(&request)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /posts" do
    before { sign_in member }

    it "lists published posts with their authors, tags and counters" do
      create(:comment, post: post_record)
      get posts_path

      expect(response).to have_http_status(:ok)
      card = page_html.find("#post_#{post_record.id}")
      expect(card).to have_link("Getting started with Rails")
      expect(card).to have_link(author.username)
      expect(card).to have_link("rails", href: posts_path(tag: "rails"))
      expect(card).to have_text("1 comment")
    end

    it "hides drafts" do
      create(:post, :draft, title: "Secret draft")
      get posts_path
      expect(page_html).to have_no_text("Secret draft")
    end

    it "filters by tag" do
      create(:post, title: "About cooking", tag_list: "food")
      get posts_path(tag: "rails")

      expect(page_html).to have_link("Getting started with Rails")
      expect(page_html).to have_no_link("About cooking")
      expect(page_html).to have_text("Posts tagged rails")
    end

    it "sorts by net votes with sort=top" do
      popular = create(:post, title: "Popular", created_at: 1.week.ago)
      popular.upvote_from(member)

      get posts_path(sort: "top")

      titles = page_html.all("article h2").map(&:text)
      expect(titles.first).to eq("Popular")
      expect(page_html).to have_css("a.active", text: "Top")
    end

    it "sorts newest first by default" do
      create(:post, title: "Old news", created_at: 1.year.ago)
      get posts_path
      titles = page_html.all("article h2").map(&:text)
      expect(titles).to eq([ "Getting started with Rails", "Old news" ])
    end

    it "shows an empty state" do
      Post.destroy_all
      get posts_path
      expect(page_html).to have_text("No posts yet.")
    end

    it "runs the same number of queries however many posts there are" do
      create_list(:post, 3, :tagged)
      get posts_path # warm up one-off queries (session, schema)

      queries_for = -> { [].tap { |sql| ActiveSupport::Notifications.subscribed(->(*, p) { sql << p[:sql] unless p[:name].in?(%w[SCHEMA CACHE]) }, "sql.active_record") { get posts_path } }.size }
      baseline = queries_for.call
      create_list(:post, 5, :tagged)

      expect(queries_for.call).to eq(baseline)
    end
  end

  describe "GET /posts/:id" do
    before { sign_in member }

    it "shows the post, its comments and similar posts" do
      create(:comment, post: post_record, body: "Great introduction!")
      create(:post, title: "Rails tips", body: post_record.body)

      get post_path(post_record)

      expect(page_html).to have_css("h1", text: "Getting started with Rails")
      expect(page_html).to have_css("#comments", text: "Great introduction!")
      expect(page_html).to have_css("aside a", text: "Rails tips")
    end

    it "shows vote counts from the counter cache" do
      post_record.upvote_from(member)
      post_record.downvote_from(moderator)
      get post_path(post_record)
      expect(page_html).to have_button("👍 1")
      expect(page_html).to have_button("👎 1")
    end

    it "sanitizes the body" do
      post_record.update!(body: %(<p onclick="steal()">Hi</p><script>alert("xss")</script><img src=x onerror=alert(1)>))
      get post_path(post_record)

      expect(response.body).not_to include("<script>alert", "onclick=", "onerror=")
      expect(page_html).to have_text("Hi")
    end

    it "hides edit and delete controls from other members" do
      get post_path(post_record)
      expect(page_html).to have_no_link("Edit", exact: true)
      expect(page_html).to have_no_button("Delete")
    end

    it "shows edit and delete controls to the author" do
      sign_in author
      get post_path(post_record)
      expect(page_html).to have_link("Edit", href: edit_post_path(post_record))
      expect(page_html).to have_button("Delete")
    end

    it "keeps drafts private" do
      draft = create(:post, :draft, user: author)
      get post_path(draft)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end

    it "returns 404 for a missing post" do
      get post_path(id: 0)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /posts/new" do
    it "renders the Trix editor" do
      sign_in member
      get new_post_path
      expect(page_html).to have_css("trix-editor[input='post_body_input']")
      expect(page_html).to have_field("Tags")
    end
  end

  describe "POST /posts" do
    before { sign_in member }

    let(:params) { { post: { title: "Hotwire tips", body: "<p>Use Turbo.</p>", tag_list: "Hotwire, Rails" } } }

    it "creates a post owned by the current member" do
      expect { post posts_path, params: params }.to change(Post, :count).by(1)

      created = Post.order(:id).last
      expect(created).to have_attributes(user: member, title: "Hotwire tips", state: nil)
      expect(created.tag_list).to contain_exactly("hotwire", "rails")
      expect(response).to redirect_to(post_path(created))
      expect(flash[:notice]).to eq("Your post was published.")
    end

    it "records the activity" do
      expect { post posts_path, params: params }.to change(PublicActivity::Activity, :count).by(1)
      expect(PublicActivity::Activity.last).to have_attributes(key: "post.create", owner: member)
    end

    it "ignores attempts to set protected attributes" do
      post posts_path, params: { post: params[:post].merge(user_id: author.id, state: "unpublished", cached_votes_up: 99) }
      expect(Post.order(:id).last).to have_attributes(user: member, state: nil, cached_votes_up: 0)
    end

    it "re-renders the form with errors when invalid" do
      expect { post posts_path, params: { post: { title: "", body: "" } } }.not_to change(Post, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(page_html).to have_text("can't be blank")
    end

    it "rejects a request without the post parameter" do
      post posts_path, params: { title: "x" }
      expect(response).to have_http_status(:bad_request)
    end

    context "with reCAPTCHA configured" do
      before { allow(Recaptcha.configuration).to receive(:site_key).and_return("site-key") }

      it "creates the post when the captcha passes" do
        allow_any_instance_of(PostsController).to receive(:verify_recaptcha).and_return(true) # rubocop:disable RSpec/AnyInstance
        expect { post posts_path, params: params }.to change(Post, :count).by(1)
      end

      it "refuses the post when the captcha fails" do
        allow_any_instance_of(PostsController).to receive(:verify_recaptcha).and_return(false) # rubocop:disable RSpec/AnyInstance
        expect { post posts_path, params: params }.not_to change(Post, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows the captcha widget on the form" do
        get new_post_path
        expect(response.body).to include("g-recaptcha")
      end
    end
  end

  describe "editing" do
    it "lets the author edit and update" do
      sign_in author
      get edit_post_path(post_record)
      expect(page_html).to have_field("Title", with: "Getting started with Rails")

      patch post_path(post_record), params: { post: { title: "Updated title" } }
      expect(response).to redirect_to(post_path(post_record.reload))
      expect(post_record.title).to eq("Updated title")
      expect(flash[:notice]).to eq("Post updated.")
    end

    it "re-renders the form when the update is invalid" do
      sign_in author
      patch post_path(post_record), params: { post: { title: "" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(post_record.reload.title).to eq("Getting started with Rails")
    end

    it "lets moderators edit" do
      sign_in moderator
      patch post_path(post_record), params: { post: { title: "Moderated" } }
      expect(post_record.reload.title).to eq("Moderated")
    end

    it "forbids other members" do
      sign_in member
      get edit_post_path(post_record)
      expect(response).to redirect_to(root_path)

      patch post_path(post_record), params: { post: { title: "Hacked" } }
      expect(post_record.reload.title).to eq("Getting started with Rails")
    end

    it "sends unauthorized members back where they came from" do
      sign_in member
      patch post_path(post_record), params: { post: { title: "Hacked" } }, headers: { "HTTP_REFERER" => posts_url }
      expect(response).to redirect_to(posts_url)
    end
  end

  describe "DELETE /posts/:id" do
    it "lets the author delete, with a 303 redirect for Turbo" do
      sign_in author
      expect { delete post_path(post_record) }.to change(Post, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(posts_path)
    end

    it "lets moderators delete" do
      sign_in moderator
      expect { delete post_path(post_record) }.to change(Post, :count).by(-1)
    end

    it "removes the post's comments too" do
      create(:comment, post: post_record)
      sign_in author
      expect { delete post_path(post_record) }.to change(Comment, :count).by(-1)
    end

    it "forbids other members" do
      sign_in member
      expect { delete post_path(post_record) }.not_to change(Post, :count)
    end
  end

  describe "voting" do
    before { sign_in member }

    it "upvotes and returns to the previous page" do
      put like_post_path(post_record), headers: { "HTTP_REFERER" => posts_url }
      expect(response).to redirect_to(posts_url)
      expect(post_record.reload.cached_votes_up).to eq(1)
    end

    it "falls back to the post when there is no previous page" do
      put like_post_path(post_record)
      expect(response).to redirect_to(post_path(post_record))
    end

    it "counts a member's vote once" do
      2.times { put like_post_path(post_record) }
      expect(post_record.reload.cached_votes_up).to eq(1)
    end

    it "switches an upvote to a downvote" do
      put like_post_path(post_record)
      put dislike_post_path(post_record)
      expect(post_record.reload).to have_attributes(cached_votes_up: 0, cached_votes_down: 1)
    end

    it "doesn't allow voting on someone else's draft" do
      draft = create(:post, :draft)
      put like_post_path(draft)
      expect(draft.reload.cached_votes_up).to eq(0)
    end
  end
end
