require "rails_helper"

RSpec.describe "Users" do
  let(:alice) { create(:user, username: "alice") }
  let!(:bob) { create(:user, username: "bob", email: "bob@sample.org") }
  let!(:carol) { create(:user, username: "carol") }

  it "requires sign-in everywhere" do
    [ users_path, user_path(bob), my_friends_path ].each do |path|
      get path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when signed in" do
    before { sign_in alice }

    describe "GET /users" do
      it "lists everyone except the current member, alphabetically" do
        get users_path
        names = page_html.all(".list-group-item .fw-semibold").map(&:text)
        expect(names).to eq(%w[bob carol])
      end

      it "searches by username or email" do
        get users_path(search: "sample.org")
        expect(page_html).to have_css("#user_#{bob.id}")
        expect(page_html).to have_no_css("#user_#{carol.id}")
      end

      it "shows Follow or Unfollow depending on the relationship" do
        create(:friendship, user: alice, friend: bob)
        get users_path
        expect(page_html.find("#user_#{bob.id}")).to have_button("Unfollow")
        expect(page_html.find("#user_#{carol.id}")).to have_button("Follow")
      end

      it "explains when nothing matches" do
        get users_path(search: "nobody")
        expect(page_html).to have_text("Nobody matches “nobody”.")
      end
    end

    describe "GET /users/:id" do
      it "shows the member's published posts and follower counts" do
        create(:post, user: bob, title: "Bob's post")
        create(:post, :draft, user: bob, title: "Bob's draft")
        create(:friendship, user: carol, friend: bob)

        get user_path(bob)

        expect(page_html).to have_css("h1", text: "bob")
        expect(page_html).to have_text("1 follower · 0 following")
        expect(page_html).to have_link("Bob's post")
        expect(page_html).to have_no_text("Bob's draft")
        expect(page_html).to have_link("Message", href: new_personal_message_path(receiver_id: bob.id))
      end

      it "hides follow and message buttons on your own profile" do
        get user_path(alice)
        expect(page_html).to have_no_button("Follow")
        expect(page_html).to have_no_link("Message", exact: true)
        expect(page_html).to have_text("No posts yet.")
      end

      it "returns 404 for a missing member" do
        get user_path(id: 0)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /my_friends" do
      it "lists who you follow and who follows you" do
        create(:friendship, user: alice, friend: bob)
        create(:friendship, user: carol, friend: alice)

        get my_friends_path

        expect(page_html).to have_css("h1", text: "Following (1)")
        expect(page_html).to have_css("h2", text: "Followers (1)")
        expect(page_html).to have_link("bob")
        expect(page_html).to have_link("carol")
      end

      it "shows empty states" do
        get my_friends_path
        expect(page_html).to have_text("You aren't following anyone yet.")
        expect(page_html).to have_text("No followers yet.")
      end

      it "shows profile pictures when present" do
        create(:friendship, user: alice, friend: create(:user, :with_avatar, username: "pictured"))
        get my_friends_path
        expect(page_html).to have_css("img.avatar[alt='pictured']")
      end
    end
  end
end
