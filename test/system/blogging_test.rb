require "application_system_test_case"

class BloggingTest < ApplicationSystemTestCase
  test "signing in and writing a post with the rich text editor" do
    visit new_user_session_path
    fill_in "Email", with: "alice@example.com"
    fill_in "Password", with: "password"
    within("main") { click_on "Log in" }
    assert_selector "h1", text: "Blog"

    click_on "Write a post"
    fill_in "Title", with: "Hotwire in practice"
    find("trix-editor").click.set("Turbo and Stimulus make Rails apps feel fast.")
    fill_in "Tags", with: "rails, hotwire"
    click_on "Create Post"

    assert_text "Your post was published."
    assert_selector "h1", text: "Hotwire in practice"
    assert_text "Turbo and Stimulus make Rails apps feel fast."
    assert_link "hotwire"
  end

  test "commenting and deleting a comment with a Turbo confirm" do
    login_as users(:bob), scope: :user
    visit post_path(posts(:rails))

    fill_in "Add a comment", with: "Thanks for sharing!"
    click_on "Post comment"
    assert_text "Comment added."
    assert_text "Thanks for sharing!"

    within "#comment_#{Comment.order(:id).last.id}" do
      accept_confirm { click_on "Delete" }
    end
    assert_text "Comment deleted."
    assert_no_text "Thanks for sharing!"
  end

  test "following someone and messaging them" do
    login_as users(:carol), scope: :user
    visit users_path

    within("#user_#{users(:bob).id}") { click_on "Follow" }
    assert_text "You are now following bob."

    within("#user_#{users(:bob).id}") { click_on "Message" }
    fill_in "Message", with: "Hi Bob, nice to meet you"
    click_on "Send"
    assert_text "Your message was sent."
    assert_text "Hi Bob, nice to meet you"
  end
end
