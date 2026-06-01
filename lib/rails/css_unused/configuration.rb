# frozen_string_literal: true

module Rails
  module CssUnused
    class Configuration
      VIEW_EXTENSIONS = %w[.html.erb .html.haml .haml .erb .slim .jbuilder].freeze
      COMPONENT_EXTENSIONS = %w[.html.erb .html.haml .haml .erb .slim].freeze
      CSS_EXTENSIONS = %w[.css .scss .sass].freeze

      attr_accessor :view_paths,
                    :component_paths,
                    :stylesheet_paths,
                    :javascript_paths,
                    :ignore_classes,
                    :ignore_selectors_matching

      def initialize
        @view_paths = ["app/views"]
        @component_paths = ["app/components"]
        @stylesheet_paths = ["app/assets/stylesheets", "app/assets/builds"]
        @javascript_paths = ["app/javascript"]
        @ignore_classes = %w[
          clearfix
          sr-only
          visually-hidden
        ]
        @ignore_selectors_matching = []
      end
    end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = nil
      end
    end
  end
end
