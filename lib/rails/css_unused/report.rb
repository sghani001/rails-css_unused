# frozen_string_literal: true

module Rails
  module CssUnused
    class Report
      Ghost = Struct.new(:class_name, keyword_init: true)

      def initialize(root:, output: $stdout, config: CssUnused.configuration)
        @root = Pathname(root)
        @output = output
        @config = config
      end

      def ghost_classes
        used = ViewScanner.new(root: @root, config: @config).used_classes
        defined = StylesheetScanner.new(root: @root, config: @config).defined_classes
        (defined - used).sort.map { |name| Ghost.new(class_name: name) }
      end

      def print_summary
        ghosts = ghost_classes
        used_count = ViewScanner.new(root: @root, config: @config).used_classes.size
        defined_count = StylesheetScanner.new(root: @root, config: @config).defined_classes.size

        @output.puts
        @output.puts "rails-css_unused — Ghost Class Report"
        @output.puts "=" * 40
        @output.puts "Project root: #{@root}"
        @output.puts "Classes in stylesheets: #{defined_count}"
        @output.puts "Classes referenced in views: #{used_count}"
        @output.puts "Ghost classes (in CSS, not in views): #{ghosts.size}"
        @output.puts

        if ghosts.empty?
          @output.puts "No ghost classes found. Nice and tidy!"
        else
          @output.puts "Ghost classes:"
          ghosts.each { |g| @output.puts "  #{g.class_name}" }
        end

        @output.puts
        @output.puts "Note: Dynamic class names and Tailwind utilities compiled at build time"
        @output.puts "may produce false positives. See README for configuration."
        @output.puts

        ghosts
      end
    end
  end
end
