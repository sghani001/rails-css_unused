# frozen_string_literal: true

module Rails
  module CssUnused
    class Railtie < Rails::Railtie
      rake_tasks do
        load File.expand_path("tasks.rake", __dir__)
      end

      initializer "rails_css_unused.configuration" do
        if Rails.application.config.respond_to?(:rails_css_unused)
          cfg = Rails.application.config.rails_css_unused
          CssUnused.configure do |c|
            c.view_paths = cfg.view_paths if cfg.respond_to?(:view_paths) && cfg.view_paths
            c.component_paths = cfg.component_paths if cfg.respond_to?(:component_paths) && cfg.component_paths
            c.stylesheet_paths = cfg.stylesheet_paths if cfg.respond_to?(:stylesheet_paths) && cfg.stylesheet_paths
            c.javascript_paths = cfg.javascript_paths if cfg.respond_to?(:javascript_paths) && cfg.javascript_paths
            c.ignore_classes = cfg.ignore_classes if cfg.respond_to?(:ignore_classes) && cfg.ignore_classes
          end
        end
      end
    end
  end
end
