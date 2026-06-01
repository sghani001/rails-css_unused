# frozen_string_literal: true

require_relative "spinner"

module Rails
  module CssUnused
    # Computes and renders the unused CSS class report.
    class Report
      Ghost = Struct.new(:class_name, :source_file, keyword_init: true)

      RESET  = "\e[0m"
      BOLD   = "\e[1m"
      RED    = "\e[31m"
      GREEN  = "\e[32m"
      YELLOW = "\e[33m"
      CYAN   = "\e[36m"
      GRAY   = "\e[90m"

      def initialize(root:, output: $stdout, config: CssUnused.configuration)
        @root   = Pathname(root)
        @output = output
        @config = config
        @tty    = output.respond_to?(:isatty) && output.isatty
      end

      # Returns Array<Ghost> of unused classes.
      def ghost_classes
        used    = Spinner.run("Scanning views & components") { ViewScanner.new(root: @root, config: @config).used_classes }
        defined = Spinner.run("Scanning stylesheets")        { StylesheetScanner.new(root: @root, config: @config).defined_classes_with_sources }

        unused_names = defined.map(&:name).to_set - used
        defined
          .select { |dc| unused_names.include?(dc.name) }
          .sort_by(&:name)
          .map { |dc| Ghost.new(class_name: dc.name, source_file: dc.source_file) }
      end

      # Prints the full report to @output.
      # Returns the exit code (0 = clean, 1 = ghosts found and fail_on_unused set).
      def print_summary
        puts_color "", nil
        puts_color "rails-css_unused v#{Rails::CssUnused::VERSION}", BOLD

        # ── Scan with spinners ────────────────────────────────────────────
        used = Spinner.run("Scanning views & components") do
          ViewScanner.new(root: @root, config: @config).used_classes
        end

        defined = Spinner.run("Scanning stylesheets") do
          StylesheetScanner.new(root: @root, config: @config).defined_classes_with_sources
        end

        ghosts = Spinner.run("Comparing & computing ghost classes") do
          unused_names = defined.map(&:name).to_set - used
          defined
            .select { |dc| unused_names.include?(dc.name) }
            .sort_by(&:name)
            .map { |dc| Ghost.new(class_name: dc.name, source_file: dc.source_file) }
        end

        # ── Report ────────────────────────────────────────────────────────
        puts_color "", nil
        puts_color "Ghost Class Report", BOLD
        puts_color "=" * 44, GRAY
        puts_color "Project root              : #{@root}", nil
        puts_color "Stylesheet classes found  : #{defined.size}", CYAN
        puts_color "View classes referenced   : #{used.size}", CYAN
        puts_color "Ghost classes (unused)    : #{ghosts.size}", ghosts.empty? ? GREEN : RED
        puts_color "", nil

        if ghosts.empty?
          puts_color "✓ No ghost classes found — stylesheet is clean!", GREEN
        else
          puts_color "Ghost classes:", BOLD
          puts_color "", nil

          ghosts.each do |g|
            if @config.show_source_files && g.source_file
              relative = g.source_file.relative_path_from(@root) rescue g.source_file
              puts_color "  #{g.class_name}", RED
              puts_color "    → #{relative}", GRAY
            else
              puts_color "  • #{g.class_name}", RED
            end
          end

          puts_color "", nil
          puts_color "Tip: Add classes to ignore_classes or ignore_patterns in your initializer", YELLOW
          puts_color "     if they are used dynamically (JS, server-side conditions, third-party).", YELLOW
        end

        puts_color "", nil
        puts_color "Note: Dynamic class names (JS conditions, runtime interpolation) may still", GRAY
        puts_color "produce false positives. Enable scan_javascript_for_classes to reduce them.", GRAY
        puts_color "", nil

        (ghosts.any? && @config.fail_on_unused) ? 1 : 0
      end

      private

      def puts_color(msg, color)
        if @tty && color
          @output.puts "#{color}#{msg}#{RESET}"
        else
          @output.puts msg
        end
      end
    end
  end
end
