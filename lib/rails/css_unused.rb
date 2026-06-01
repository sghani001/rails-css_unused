# frozen_string_literal: true

require "pathname"
require "set"

require_relative "css_unused/version"
require_relative "css_unused/configuration"
require_relative "css_unused/view_scanner"
require_relative "css_unused/stylesheet_scanner"
require_relative "css_unused/report"

module Rails
  module CssUnused
    class Error < StandardError; end

    class << self
      def report(root: default_root, output: $stdout)
        Report.new(root: root, output: output).print_summary
      end

      def ghost_classes(root: default_root)
        Report.new(root: root).ghost_classes.map(&:class_name)
      end

      def default_root
        if defined?(Rails) && Rails.respond_to?(:root)
          Rails.root
        else
          Pathname.new(Dir.pwd)
        end
      end
    end
  end
end

require_relative "css_unused/railtie" if defined?(Rails::Railtie)
