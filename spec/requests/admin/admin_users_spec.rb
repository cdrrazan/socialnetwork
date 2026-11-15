require "rails_helper"

RSpec.describe "Admin admin users" do
  before { sign_in create(:admin_user, email: "first@example.com") }

  it "lists admins" do
    get admin_admin_users_path
    expect(page_html).to have_text("first@example.com")
  end

  it "creates another admin" do
    expect {
      post admin_admin_users_path, params: { admin_user: { email: "second@example.com", password: "password123",
                                                          password_confirmation: "password123" } }
    }.to change(AdminUser, :count).by(1)
  end

  it "renders the form" do
    get new_admin_admin_user_path
    expect(page_html).to have_field("Password confirmation")
  end

  it "filters by email" do
    create(:admin_user, email: "other@example.com")
    get admin_admin_users_path(q: { email_cont: "first" })
    expect(page_html).to have_text("first@example.com")
    expect(page_html).to have_no_text("other@example.com")
  end
end
