# frozen_string_literal: true

require "rails/css_unused"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    Rails::CssUnused.reset_configuration!
  end
end
