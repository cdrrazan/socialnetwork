require "rails_helper"

RSpec.describe "Admin users" do
  let!(:member) { create(:user, username: "alice", email: "alice@example.com") }

  before { sign_in create(:admin_user) }

  it "lists members" do
    create(:user, username: "bob")
    get admin_users_path
    expect(page_html).to have_text("alice").and have_text("bob")
  end

  it "filters by email" do
    create(:user, email: "bob@example.com")
    get admin_users_path(q: { email_cont: "alice" })
    expect(page_html).to have_css("td", text: "alice@example.com")
    expect(page_html).to have_no_css("td", text: "bob@example.com")
  end

  it "shows a member without leaking credentials" do
    get admin_user_path(member)
    expect(page_html).to have_text("alice@example.com")
    expect(response.body).not_to include(member.encrypted_password)
  end

  it "grants moderator rights but nothing else" do
    get edit_admin_user_path(member)
    expect(page_html).to have_field("user[admin]")

    patch admin_user_path(member), params: { user: { admin: "1", email: "hijack@example.com", username: "hacked" } }

    member.reload
    expect(member.admin).to be(true)
    expect(member.email).to eq("alice@example.com")
    expect(member.username).to eq("alice")
  end

  it "doesn't create members from the admin panel" do
    expect(Rails.application.routes.url_helpers).not_to respond_to(:new_admin_user_path)
    get admin_users_path
    expect(page_html).to have_no_link("New User")
  end

  it "deletes a member" do
    expect { delete admin_user_path(member) }.to change(User, :count).by(-1)
  end
end
