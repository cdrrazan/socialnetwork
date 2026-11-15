require "capybara/cuprite"

# Cuprite drives Chrome over the DevTools protocol, so no chromedriver is
# needed. BROWSER_PATH picks a specific Chrome/Chromium binary and
# HEADLESS=false shows the browser while specs run.
Capybara.register_driver(:devstory_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1400, 1000 ],
    browser_path: ENV["BROWSER_PATH"],
    browser_options: { "no-sandbox": nil },
    process_timeout: 20,
    timeout: 10,
    headless: ENV["HEADLESS"] != "false"
  )
end

Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :devstory_cuprite
  end
end
