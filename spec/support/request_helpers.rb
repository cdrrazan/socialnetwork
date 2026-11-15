module RequestHelpers
  # Parsed HTML of the last response, for CSS assertions in request specs.
  def page_html
    Capybara.string(response.body)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
