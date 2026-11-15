require "rails_helper"

RSpec.describe "Blogging", :js do
  let(:author) { create(:user, username: "author") }

  it "writes a post with the rich text editor and tags" do
    sign_in author
    visit posts_path

    click_on "Write a post"
    fill_in "Title", with: "Hotwire in practice"
    find("trix-editor").click
    find("trix-editor").send_keys("Turbo and Stimulus make Rails apps feel fast.")
    fill_in "Tags", with: "Rails, Hotwire"
    click_on "Create Post"

    expect(page).to have_text("Your post was published.")
    expect(page).to have_css("h1", text: "Hotwire in practice")
    expect(page).to have_css(".post-body", text: "Turbo and Stimulus make Rails apps feel fast.")
    expect(page).to have_link("hotwire")
    expect(page).to have_link("rails")
  end

  it "keeps the form and shows errors when the post is invalid" do
    sign_in author
    visit new_post_path
    fill_in "Title", with: "No body"
    click_on "Create Post"

    expect(page).to have_text("can't be blank")
    expect(page).to have_field("Title", with: "No body")
  end

  it "edits a post" do
    post = create(:post, user: author, title: "Draft title")
    sign_in author
    visit post_path(post)

    click_on "Edit", exact: true
    fill_in "Title", with: "Final title"
    click_on "Update Post"

    expect(page).to have_text("Post updated.")
    expect(page).to have_css("h1", text: "Final title")
  end

  it "deletes a post after confirming" do
    post = create(:post, user: author, title: "Short-lived")
    sign_in author
    visit post_path(post)

    accept_confirm("Delete this post?") { click_on "Delete" }

    expect(page).to have_text("Post deleted.")
    expect(page).to have_no_text("Short-lived")
  end

  it "keeps the post when the deletion is dismissed" do
    post = create(:post, user: author)
    sign_in author
    visit post_path(post)

    dismiss_confirm { click_on "Delete" }

    expect(page).to have_css("h1", text: post.title)
    expect(Post.exists?(post.id)).to be(true)
  end

  it "votes on a post" do
    post = create(:post)
    sign_in create(:user)
    visit post_path(post)

    click_on "👍 0"
    expect(page).to have_button("👍 1")

    click_on "👎 0"
    expect(page).to have_button("👍 0")
    expect(page).to have_button("👎 1")
  end

  it "filters by tag and sorts by votes" do
    create(:post, title: "Rails post", tag_list: "rails", created_at: 1.day.ago).upvote_from(author)
    create(:post, title: "Newest post", tag_list: "life")
    sign_in author

    visit posts_path
    expect(page.all("article h2").map(&:text)).to eq([ "Newest post", "Rails post" ])

    click_on "Top"
    expect(page.all("article h2").map(&:text)).to eq([ "Rails post", "Newest post" ])

    click_on "rails"
    expect(page).to have_text("Posts tagged rails")
    expect(page).to have_no_text("Newest post")
  end

  it "comments, edits and deletes a comment" do
    post = create(:post)
    sign_in author
    visit post_path(post)

    fill_in "Add a comment", with: "Thanks for sharing!"
    click_on "Post comment"
    expect(page).to have_text("Comment added.")

    within("#comments") { click_on "Edit" }
    fill_in "Comment", with: "Thanks a lot for sharing!"
    click_on "Update comment"
    expect(page).to have_text("Thanks a lot for sharing!")

    within("#comment_#{Comment.last.id}") do
      accept_confirm { click_on "Delete" }
    end
    expect(page).to have_text("Comment deleted.")
    expect(page).to have_no_text("Thanks a lot for sharing!")
  end

  it "suggests similar posts" do
    post = create(:post, title: "Rails routing", body: "Rails routing maps URLs to controllers in Rails.")
    create(:post, title: "Rails controllers", body: "Controllers in Rails handle requests from routing.")
    sign_in author

    visit post_path(post)
    within("aside") { click_on "Rails controllers" }

    expect(page).to have_css("h1", text: "Rails controllers")
  end
end
