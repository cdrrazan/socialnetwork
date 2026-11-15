require "rails_helper"

RSpec.describe "Admin access" do
  it "sends visitors to the admin login" do
    get admin_root_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "doesn't let members in, even moderators" do
    sign_in create(:user, :moderator)
    get admin_root_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end

  it "logs in through the admin form" do
    create(:admin_user, email: "boss@example.com", password: "password")
    post admin_user_session_path, params: { admin_user: { email: "boss@example.com", password: "password" } }
    expect(response).to redirect_to(admin_root_path)
  end

  it "logs out with DELETE" do
    sign_in create(:admin_user)
    delete destroy_admin_user_session_path
    get admin_root_path
    expect(response).to redirect_to(new_admin_user_session_path)
  end
end
