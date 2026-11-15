require "rails_helper"

RSpec.describe "Authentication", :js do
  it "signs up, logs out and logs back in" do
    visit root_path
    within("nav") { click_on "Sign up" }

    fill_in "Username", with: "newdev"
    fill_in "Email", with: "newdev@example.com"
    fill_in "Password", with: "password", match: :prefer_exact
    fill_in "Password confirmation", with: "password"
    within("main") { click_on "Sign up" }

    expect(page).to have_css("h1", text: "Blog")
    expect(page).to have_text("Welcome! You have signed up successfully.")

    click_on "newdev"
    click_on "Sign out"
    expect(page).to have_css("h1", text: "Your dev circle")

    within("nav") { click_on "Log in" }
    fill_in "Email", with: "newdev@example.com"
    fill_in "Password", with: "password"
    within("main") { click_on "Log in" }
    expect(page).to have_text("Signed in successfully.")
  end

  it "shows an error for a wrong password" do
    create(:user, email: "member@example.com")

    visit new_user_session_path
    fill_in "Email", with: "member@example.com"
    fill_in "Password", with: "wrong"
    within("main") { click_on "Log in" }

    expect(page).to have_text("Invalid email or password.")
    expect(page).to have_current_path(new_user_session_path)
  end

  it "shows validation errors on sign-up" do
    visit new_user_registration_path
    fill_in "Username", with: "bad name!"
    within("main") { click_on "Sign up" }

    expect(page).to have_text("may only contain letters, numbers, _ . and -")
    expect(page).to have_text("can't be blank")
  end
end
