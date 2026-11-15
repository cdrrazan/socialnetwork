require "rails_helper"

RSpec.describe "Responsive layout", :js do
  it "collapses the navigation into a menu on small screens" do
    page.driver.resize(390, 844)
    sign_in create(:user)
    visit posts_path

    expect(page).to have_no_link("Forum")
    find("button.navbar-toggler").click
    expect(page).to have_link("Forum")
  ensure
    page.driver.resize(1400, 1000)
  end
end
