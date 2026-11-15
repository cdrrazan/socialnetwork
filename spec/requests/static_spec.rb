require "rails_helper"

RSpec.describe "Static pages" do
  describe "GET /" do
    it "shows the landing page to visitors" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(page_html).to have_css("h1", text: "Your dev circle")
      expect(page_html).to have_link("Join today", href: new_user_registration_path)
    end

    it "shows the blog to signed-in members" do
      sign_in create(:user)
      get root_path
      expect(page_html).to have_css("h1", text: "Blog")
    end
  end

  %w[about contact].each do |page|
    describe "GET /#{page}" do
      it "is public" do
        get "/#{page}"
        expect(response).to have_http_status(:ok)
        expect(page_html).to have_css("h1", text: page.capitalize)
      end
    end
  end

  describe "GET /profile" do
    it "requires sign-in" do
      get profile_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the member's own posts, questions and follower counts" do
      user = create(:user, username: "alice")
      create(:post, user: user, title: "My first post")
      create(:question, user: user, title: "My question?")
      create(:friendship, friend: user)
      sign_in user

      get profile_path

      expect(page_html).to have_css("h1", text: "alice")
      expect(page_html).to have_text("My first post")
      expect(page_html).to have_link("My question?")
      expect(page_html).to have_link("1 follower")
    end

    it "shows empty states" do
      sign_in create(:user)
      get profile_path
      expect(page_html).to have_text("You haven't written anything yet.")
      expect(page_html).to have_text("No questions yet.")
    end
  end

  describe "GET /settings" do
    it "requires sign-in" do
      get settings_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "offers account deletion" do
      sign_in create(:user)
      get settings_path
      expect(page_html).to have_button("Delete my account")
    end
  end

  describe "GET /up" do
    it "reports the app is healthy" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "browser support" do
    it "turns away very old browsers" do
      get about_path, headers: { "User-Agent" => "Mozilla/5.0 (Windows NT 6.1; Trident/7.0; rv:11.0) like Gecko" }
      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
