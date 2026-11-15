require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Cuprite drives Chrome over the DevTools protocol, so no chromedriver is
  # needed. Set BROWSER_PATH to use a specific Chrome/Chromium binary.
  driven_by :cuprite, screen_size: [ 1400, 1000 ], options: {
    browser_path: ENV["BROWSER_PATH"],
    browser_options: { "no-sandbox": nil },
    process_timeout: 20,
    headless: ENV["HEADLESS"] != "false"
  }.compact

  include Warden::Test::Helpers

  teardown { Warden.test_reset! }
end
