# frozen_string_literal: true

module Rails
  module CssUnused
    class Configuration
      # File extensions treated as view templates
      VIEW_EXTENSIONS       = %w[.erb .haml .slim].freeze
      # Compound view extensions (e.g. foo.html.erb)
      COMPOUND_VIEW_ENDINGS = %w[.html.erb .html.haml .html.slim].freeze
      # CSS/preprocessor extensions to scan
      CSS_EXTENSIONS        = %w[.css .scss .sass].freeze
      # Ruby component file extensions
      COMPONENT_EXTENSIONS  = %w[.rb].freeze

      # ── Scan paths ────────────────────────────────────────────────────────
      # Directories to search for view templates (relative to project root).
      attr_accessor :view_paths

      # Directories to search for ViewComponent / Phlex / etc. template files.
      attr_accessor :component_paths

      # Directories to search for stylesheets.
      attr_accessor :stylesheet_paths

      # Directories to search for JS files (e.g. Stimulus controllers that
      # add classes dynamically — detected as allowlisted dynamic patterns).
      attr_accessor :javascript_paths

      # ── Ignore lists ─────────────────────────────────────────────────────
      # Exact class names to always treat as "used" (never reported as ghost).
      # Good for: utility classes, JS-hook classes, server-side rendered classes.
      attr_accessor :ignore_classes

      # Regex patterns — any CSS class name matching any pattern is ignored.
      # Good for: third-party prefixes, state classes, BEM modifier variants.
      # Example: [/\Ajs-/, /\Ais-/, /\Ahas-/]
      attr_accessor :ignore_patterns

      # ── Dynamic class detection ───────────────────────────────────────────
      # When true, scan JS/Stimulus files for string literals that look like
      # CSS class names and add them to the used-class set automatically.
      attr_accessor :scan_javascript_for_classes

      # When true, scan Ruby component files (.rb) for string literals that
      # look like CSS classes passed to html attributes.
      attr_accessor :scan_ruby_components

      # ── Output ───────────────────────────────────────────────────────────
      # When true, show which file each ghost class was defined in.
      attr_accessor :show_source_files

      # When true, exit with code 1 if any ghost classes are found.
      # Useful for CI pipelines.
      attr_accessor :fail_on_unused

      def initialize
        @view_paths       = %w[app/views]
        @component_paths  = %w[app/components]
        @stylesheet_paths = %w[app/assets/stylesheets app/assets/builds]
        @javascript_paths = %w[app/javascript]

        @ignore_classes = %w[
          clearfix sr-only visually-hidden
          active disabled selected current open closed
          show hide hidden visible
          fade collapse collapsing
        ]

        @ignore_patterns = [
          /\Ajs-/,       # JS-hook classes
          /\Ais-/,       # state classes  (is-active, is-open)
          /\Ahas-/,      # state classes  (has-error)
          /\Adata-/,     # sometimes leaked into CSS scanners
        ]

        @scan_javascript_for_classes = true
        @scan_ruby_components        = true
        @show_source_files           = false
        @fail_on_unused              = false
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
