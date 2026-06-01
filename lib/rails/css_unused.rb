# frozen_string_literal: true

require "pathname"
require "set"

require_relative "css_unused/version"
require_relative "css_unused/configuration"
require_relative "css_unused/stylesheet_scanner"
require_relative "css_unused/view_scanner"
require_relative "css_unused/report"

module Rails
  module CssUnused
    class Error < StandardError; end

    class << self
      # Prints a full report to output (default: $stdout).
      # Returns the exit code (0 = clean, 1 = ghosts found + fail_on_unused).
      def report(root: default_root, output: $stdout)
        Report.new(root: root, output: output).print_summary
      end

      # Returns an array of unused class name strings.
      def ghost_classes(root: default_root)
        Report.new(root: root).ghost_classes.map(&:class_name)
      end

      # Returns the project root: Rails.root if inside Rails, else cwd.
      def default_root
        if defined?(::Rails) && ::Rails.respond_to?(:root) && ::Rails.root
          ::Rails.root
        else
          Pathname.new(Dir.pwd)
        end
      end
    end
  end
end

require_relative "css_unused/railtie" if defined?(Rails::Railtie)
