require "rails_helper"

RSpec.describe "Admin dashboard" do
  before { sign_in create(:admin_user) }

  it "shows headline counts and the latest content" do
    create(:post, title: "Fresh post")
    create(:post, :draft)
    create(:user, username: "newcomer")
    create(:question, title: "Fresh question?")

    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(page_html).to have_text("2 posts (1 awaiting publication)")
    expect(page_html).to have_link("Fresh post")
    expect(page_html).to have_link("newcomer")
    expect(page_html).to have_link("Fresh question?")
  end

  it "limits each panel to the ten most recent records" do
    create_list(:post, 12)
    get admin_root_path
    expect(page_html.find(".panel", text: "Recent posts")).to have_css("li", count: 10)
  end
end
