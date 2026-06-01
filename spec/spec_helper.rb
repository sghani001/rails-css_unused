# frozen_string_literal: true

require "bundler/setup"
require "pathname"
require "set"
require "rails/css_unused"

FIXTURES_ROOT = Pathname(__dir__).join("fixtures", "sample_app")

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  config.before(:each) do
    Rails::CssUnused.reset_configuration!
    Rails::CssUnused.configure do |c|
      c.stylesheet_paths            = ["app/assets/stylesheets"]
      c.view_paths                  = ["app/views"]
      c.component_paths             = ["app/components"]
      c.javascript_paths            = ["app/javascript"]
      c.ignore_classes              = []
      c.ignore_patterns             = []
      c.scan_javascript_for_classes = false
      c.scan_ruby_components        = false
      c.show_source_files           = false
      c.fail_on_unused              = false
    end
  end
end
