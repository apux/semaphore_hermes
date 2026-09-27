require "capybara/rspec/matchers"

module HtmlMatchers
  def html
    Capybara.string(response.body)
  end
end

RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :request
  config.include HtmlMatchers, type: :request
end
