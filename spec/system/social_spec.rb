require "rails_helper"

RSpec.describe "Following and messaging", :js do
  let(:me) { create(:user, username: "me") }
  let!(:bob) { create(:user, username: "bob") }

  before { sign_in me }

  it "follows, sees activity, and unfollows" do
    visit users_path
    within("#user_#{bob.id}") { click_on "Follow" }
    expect(page).to have_text("You are now following bob.")

    create(:post, user: bob, title: "Bob's news").create_activity(:create, owner: bob)
    visit activities_path
    expect(page).to have_text("bob published Bob's news")

    visit my_friends_path
    accept_confirm { click_on "Unfollow" }
    expect(page).to have_text("You unfollowed bob.")
    expect(page).to have_text("You aren't following anyone yet.")
  end

  it "sends private messages and keeps the newest one in view" do
    visit user_path(bob)
    click_on "Message"

    fill_in "Message", with: "Hi Bob, nice to meet you"
    click_on "Send"
    expect(page).to have_text("Your message was sent.")

    conversation = Conversation.last
    create_list(:personal_message, 15, conversation: conversation, user: bob, body: "Message from Bob")
    fill_in "personal_message[body]", with: "The latest reply"
    click_on "Reply"

    expect(page).to have_text("The latest reply")
    at_bottom = page.evaluate_script(<<~JS)
      (() => { const el = document.querySelector(".conversation-body"); return el.scrollTop + el.clientHeight >= el.scrollHeight - 2 })()
    JS
    expect(at_bottom).to be(true)
  end

  it "edits the profile and uploads a picture" do
    visit edit_user_registration_path
    attach_file "Profile picture", Rails.root.join("spec/fixtures/files/avatar.png")
    fill_in "Current password", with: "password"
    click_on "Update"

    expect(page).to have_text("Your account has been updated successfully.")
    expect(me.reload.avatar).to be_attached
  end
end
