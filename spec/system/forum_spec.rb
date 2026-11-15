require "rails_helper"

RSpec.describe "Forum" do
  it "lets visitors read questions without an account" do
    question = create(:question, title: "Public question?")
    create(:answer, question: question, body: "Public answer")

    visit questions_path
    click_on "Public question?"

    expect(page).to have_text("Public answer")
    expect(page).to have_link("Log in")
  end

  it "asks a question and answers it", :js do
    sign_in create(:user)
    visit questions_path

    click_on "Ask a question"
    fill_in "Title", with: "How do I test Stimulus controllers?"
    fill_in "Details", with: "I want to unit test them."
    click_on "Ask question"
    expect(page).to have_text("Question was successfully created.")

    fill_in "Your answer", with: "Use a system spec with a real browser."
    click_on "Post answer"
    expect(page).to have_text("Your answer was submitted.")
    expect(page).to have_css("h2", text: "1 answer")

    accept_confirm { within(".card") { click_on "Delete" } }
    expect(page).to have_css("h2", text: "0 answers")
  end
end
