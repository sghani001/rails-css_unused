# frozen_string_literal: true

module Rails
  module CssUnused
    class Railtie < Rails::Railtie
      rake_tasks do
        load File.expand_path("tasks.rake", __dir__)
      end

      # Support configuration via config/initializers/css_unused.rb:
      #
      #   Rails::CssUnused.configure do |c|
      #     c.fail_on_unused        = true
      #     c.show_source_files     = true
      #     c.ignore_patterns       << /\Ashopify-/
      #     c.scan_javascript_for_classes = true
      #   end
      #
      initializer "rails_css_unused.configuration" do
        # Nothing auto-applied — users configure via Rails::CssUnused.configure.
        # The Railtie merely makes rake tasks available.
      end
    end
  end
end
