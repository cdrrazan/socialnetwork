require "rails_helper"

RSpec.describe "Accounts (Devise)" do
  describe "signing up" do
    it "creates an account with a username and signs the member in" do
      expect {
        post user_registration_path, params: { user: { username: "newbie", email: "newbie@example.com",
                                                       password: "password", password_confirmation: "password" } }
      }.to change(User, :count).by(1)

      expect(User.order(:id).last).to have_attributes(username: "newbie", permalink: "newbie", admin: false)
      expect(response).to redirect_to(root_path)
    end

    it "ignores attempts to make yourself a moderator" do
      post user_registration_path, params: { user: { username: "sneaky", email: "s@example.com", admin: "1",
                                                     password: "password", password_confirmation: "password" } }
      expect(User.find_by!(username: "sneaky").admin).to be(false)
    end

    it "shows errors" do
      post user_registration_path, params: { user: { username: "", email: "bad", password: "x", password_confirmation: "y" } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(page_html).to have_text("can't be blank")
    end
  end

  describe "logging in and out" do
    let!(:user) { create(:user, email: "member@example.com", password: "password") }

    it "logs in with email and password" do
      post user_session_path, params: { user: { email: "member@example.com", password: "password" } }
      expect(response).to redirect_to(root_path)
    end

    it "rejects a wrong password" do
      post user_session_path, params: { user: { email: "member@example.com", password: "nope" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "logs out with DELETE" do
      sign_in user
      delete destroy_user_session_path
      get posts_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "editing the profile" do
    let(:user) { create(:user, username: "alice", password: "password") }

    before { sign_in user }

    it "updates the username and avatar" do
      put user_registration_path, params: {
        user: { username: "alice_new", email: user.email, current_password: "password",
                avatar: fixture_file_upload("avatar.png", "image/png") }
      }

      user.reload
      expect(user.username).to eq("alice_new")
      expect(user.avatar).to be_attached
      expect(user.avatar.content_type).to eq("image/png")
    end

    it "rejects non-image avatars" do
      put user_registration_path, params: {
        user: { username: "alice", email: user.email, current_password: "password",
                avatar: Rack::Test::UploadedFile.new(StringIO.new("text"), "text/plain", original_filename: "x.txt") }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.avatar).not_to be_attached
    end

    it "requires the current password" do
      put user_registration_path, params: { user: { username: "changed", email: user.email, current_password: "wrong" } }
      expect(user.reload.username).to eq("alice")
    end

    it "deletes the account and everything in it" do
      create(:post, user: user)
      expect { delete user_registration_path }.to change(User, :count).by(-1).and change(Post, :count).by(-1)
    end
  end

  describe "password reset" do
    it "emails reset instructions from the app's sender address" do
      user = create(:user, email: "forgetful@example.com")

      expect { post user_password_path, params: { user: { email: user.email } } }
        .to change(ActionMailer::Base.deliveries, :count).by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "forgetful@example.com" ])
      expect(mail[:from].to_s).to eq(ApplicationMailer.default_sender)
      expect(mail.subject).to eq("Reset password instructions")
      expect(mail.body.encoded).to include("Change my password")
    end

    it "shows the reset form for a valid token" do
      user = create(:user)
      token = user.send_reset_password_instructions
      get edit_user_password_path(reset_password_token: token)
      expect(page_html).to have_button("Change my password")
    end
  end

  describe "pages" do
    %w[/users/sign_in /users/sign_up /users/password/new].each do |path|
      it "renders #{path}" do
        get path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
