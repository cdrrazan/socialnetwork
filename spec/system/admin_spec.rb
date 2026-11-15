require "rails_helper"

RSpec.describe "Admin panel", :js do
  it "publishes a drafted announcement" do
    create(:user, email: "editor@example.com")
    create(:admin_user, email: "editor@example.com", password: "password")

    visit new_admin_user_session_path
    fill_in "Email", with: "editor@example.com"
    fill_in "Password", with: "password"
    click_on "Login"
    expect(page).to have_text("Dashboard")

    visit new_admin_post_path
    fill_in "Title", with: "Meetup on Friday"
    fill_in "Body", with: "Join us at 6pm."
    click_on "Create Post"
    expect(page).to have_css(".status_tag", text: /unpublished/i)

    click_on "Publish"
    expect(page).to have_text("Post published.")
    expect(Post.find_by!(title: "Meetup on Friday")).to be_published
  end
end
