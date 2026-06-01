# frozen_string_literal: true

module Rails
  module CssUnused
    # Scans Rails view templates, ViewComponent files, Phlex components,
    # Stimulus controllers, and Ruby files for referenced CSS class names.
    #
    # Handles:
    #   ERB:       class="foo bar",  class: "foo",  class: ["foo", "bar"]
    #   HAML:      .foo.bar,  %div.foo
    #   Slim:      div.foo,  .foo
    #   Ruby:      html_class: "foo",  css_classes("foo bar"),  "foo bar"
    #   Stimulus:  this.element.classList.add("foo"),  "foo" string literals
    #   Dynamic:   class="<%= cond ? 'foo' : 'bar' %>" — literal parts extracted
    class ViewScanner
      # ── ERB / HTML patterns ──────────────────────────────────────────────
      # class="foo bar baz"  or  class='foo bar'
      HTML_CLASS_ATTR   = /class\s*=\s*["']([^"'<>]+)["']/i
      # class: "foo bar"  or  class: 'foo'
      RUBY_CLASS_KV     = /class:\s*["']([^"']+)["']/
      # class: ["foo", "bar"]  or  class: %w[foo bar]
      RUBY_CLASS_ARRAY  = /class:\s*(?:\[|%w\[)\s*([^\]\n]+)/
      # tag.div(class: "foo")  content_tag(:div, class: "foo")
      TAG_HELPER        = /(?:content_tag|tag\.\w+)\s*[({][^)}\n]*class:\s*["']([^"']+)["']/

      # ── HAML patterns ───────────────────────────────────────────────────
      # .foo, %div.foo.bar, %span.foo#id
      HAML_IMPLICIT     = /^[ \t]*(?:%[\w:-]+)?(\.[a-zA-Z][a-zA-Z0-9_-]*(?:\.[a-zA-Z][a-zA-Z0-9_-]*)*)/
      # Inline { class: "foo" }
      HAML_HASH_CLASS   = /class:\s*["']([^"']+)["']/

      # ── Slim patterns ───────────────────────────────────────────────────
      # div.foo.bar or .foo.bar on its own line
      SLIM_CLASS        = /^[ \t]*(?:[\w-]*)(\.[a-zA-Z][a-zA-Z0-9_-]*(?:\.[a-zA-Z][a-zA-Z0-9_-]*)*)/

      # ── ERB dynamic interpolation ────────────────────────────────────────
      # class="<%= expr %>", class="prefix-<%= var %>"  — extracts static parts
      ERB_DYNAMIC_CLASS = /class\s*=\s*["'][^"']*<%=[^%]+%>[^"']*["']/m

      # ── Ruby / Stimulus string literals ─────────────────────────────────
      # Any double-quoted string that looks like a space-separated class list
      # Used when scan_javascript_for_classes or scan_ruby_components is on.
      JS_ADD_CLASS      = /(?:classList\.add|classList\.toggle|classList\.replace)\s*\(\s*["']([^"']+)["']/
      JS_REMOVE_CLASS   = /(?:classList\.remove)\s*\(\s*["']([^"']+)["']/  # these ARE used
      RUBY_STRING_CLASSES = /["']([a-zA-Z][a-zA-Z0-9_-]*(?:\s+[a-zA-Z][a-zA-Z0-9_-]*)*)["']/

      def initialize(root:, config: CssUnused.configuration)
        @root   = Pathname(root)
        @config = config
      end

      # Returns a Set of class name strings referenced across all view files.
      def used_classes
        classes     = Set.new
        ignore_set  = @config.ignore_classes.map(&:to_s).to_set
        ignore_pats = Array(@config.ignore_patterns)

        each_view_file do |path, content|
          extract_from(content, path).each do |cls|
            next if ignore_set.include?(cls)
            next if ignore_pats.any? { |p| cls.match?(p) }
            classes << cls
          end
        end

        if @config.scan_javascript_for_classes
          each_js_file do |path, content|
            extract_js_classes(content).each { |cls| classes << cls }
          end
        end

        classes
      end

      private

      # ── File iteration ───────────────────────────────────────────────────

      def each_view_file
        paths = (@config.view_paths + @config.component_paths).uniq
        paths.each do |rel|
          dir = @root.join(rel)
          next unless dir.directory?

          Dir.glob(dir.join("**", "*")).each do |f|
            path = Pathname(f)
            next unless path.file? && view_file?(path)

            content = safe_read(path)
            yield path, content if content
          end
        end
      end

      def each_js_file
        @config.javascript_paths.each do |rel|
          dir = @root.join(rel)
          next unless dir.directory?

          Dir.glob(dir.join("**", "*.{js,ts,jsx,tsx}")).each do |f|
            path    = Pathname(f)
            content = safe_read(path)
            yield path, content if content
          end
        end

        # Also scan Ruby component files if configured
        return unless @config.scan_ruby_components

        @config.component_paths.each do |rel|
          dir = @root.join(rel)
          next unless dir.directory?

          Dir.glob(dir.join("**", "*.rb")).each do |f|
            path    = Pathname(f)
            content = safe_read(path)
            yield path, content if content
          end
        end
      end

      def view_file?(path)
        name = path.basename.to_s
        Configuration::VIEW_EXTENSIONS.any? { |ext| name.end_with?(ext) } ||
          Configuration::COMPOUND_VIEW_ENDINGS.any? { |ext| name.end_with?(ext) }
      end

      # ── Class extraction ─────────────────────────────────────────────────

      def extract_from(content, path)
        found = Set.new
        ext   = path.extname
        base  = path.basename.to_s

        # ERB / HTML (also used for .html.erb compound names)
        if ext == ".erb" || base.end_with?(".html.erb")
          found.merge extract_erb(content)
        end

        # HAML
        if ext == ".haml" || base.end_with?(".html.haml")
          found.merge extract_haml(content)
        end

        # Slim
        if ext == ".slim" || base.end_with?(".html.slim")
          found.merge extract_slim(content)
        end

        # Ruby files (ViewComponent .rb, Phlex, helpers)
        if ext == ".rb"
          found.merge extract_ruby(content)
        end

        found
      end

      def extract_erb(content)
        found = Set.new

        # Standard class attributes
        [HTML_CLASS_ATTR, RUBY_CLASS_KV, TAG_HELPER].each do |pat|
          content.scan(pat) { |m| found.merge tokenize(m[0]) }
        end

        # class: ["foo", "bar"]  /  class: %w[foo bar]
        content.scan(RUBY_CLASS_ARRAY) do |m|
          found.merge tokenize(m[0].gsub(/["',]/, " "))
        end

        # ERB dynamic class attributes — extract static string parts
        content.scan(ERB_DYNAMIC_CLASS) do
          chunk = Regexp.last_match(0)
          # Strip ERB tags, grab remaining quoted tokens
          stripped = chunk.gsub(/<%.*?%>/m, " ")
          stripped.scan(/["']([^"']+)["']/) { |m| found.merge tokenize(m[0]) }
        end

        found
      end

      def extract_haml(content)
        found = Set.new

        content.scan(HAML_IMPLICIT) do |m|
          # m[0] = ".foo.bar" — split on dots
          m[0].split(".").reject(&:empty?).each do |cls|
            found << cls if valid_class?(cls)
          end
        end

        content.scan(HAML_HASH_CLASS) { |m| found.merge tokenize(m[0]) }
        content.scan(RUBY_CLASS_KV)   { |m| found.merge tokenize(m[0]) }

        found
      end

      def extract_slim(content)
        found = Set.new

        content.scan(SLIM_CLASS) do |m|
          m[0].split(".").reject(&:empty?).each do |cls|
            found << cls if valid_class?(cls)
          end
        end

        content.scan(RUBY_CLASS_KV) { |m| found.merge tokenize(m[0]) }

        found
      end

      def extract_ruby(content)
        found = Set.new

        # ViewComponent / Phlex: render with class: "foo"
        content.scan(RUBY_CLASS_KV)   { |m| found.merge tokenize(m[0]) }
        content.scan(RUBY_CLASS_ARRAY) { |m| found.merge tokenize(m[0].gsub(/["',]/, " ")) }

        # Loose string literals that look like class name lists (safe: validated below)
        content.scan(RUBY_STRING_CLASSES) do |m|
          tokens = tokenize(m[0])
          # Only trust them if every token is a plausible CSS class
          found.merge(tokens) if tokens.all? { |t| valid_class?(t) }
        end

        found
      end

      def extract_js_classes(content)
        found = Set.new
        content.scan(JS_ADD_CLASS)    { |m| found.merge tokenize(m[0]) }
        content.scan(JS_REMOVE_CLASS) { |m| found.merge tokenize(m[0]) }
        found
      end

      # ── Helpers ───────────────────────────────────────────────────────────

      # Splits a raw class attribute value into individual class tokens.
      # Handles: spaces, commas, quotes, ERB fragments.
      def tokenize(raw)
        return Set.new if raw.nil?

        raw
          .gsub(/["']/, " ")               # strip stray quotes
          .split(/[\s,]+/)                  # split on whitespace/commas
          .map { |t| t.strip.delete_prefix(".") }
          .reject(&:empty?)
          .reject { |t| t.include?("<%") || t.include?('#{') }
          .select { |t| valid_class?(t) }
          .to_set
      end

      # A valid CSS class token: starts with a letter or underscore,
      # contains only alphanumeric, hyphens, underscores.
      # Allows BEM: block__element--modifier
      def valid_class?(token)
        token.match?(/\A-?[a-zA-Z_][a-zA-Z0-9_-]*\z/)
      end

      def safe_read(path)
        path.read(encoding: "UTF-8")
      rescue ArgumentError, Encoding::UndefinedConversionError
        path.read(encoding: "BINARY").encode("UTF-8", invalid: :replace, undef: :replace)
      rescue Errno::ENOENT, Errno::EACCES
        nil
      end
    end
  end
end
