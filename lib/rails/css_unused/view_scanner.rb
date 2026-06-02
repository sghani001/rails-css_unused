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
    #   Dynamic vars: status_class = "foo-bar" — string assigned to *_class/*_classes var
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

      # ── Dynamic class variable detection (v0.2.1) ────────────────────────
      # Detects string literals assigned to variables whose name ends with
      # _class, _classes, _style, or _css — and the string contains hyphens
      # (Ruby variable names cannot contain hyphens, so it must be a value).
      #
      # Matches patterns like:
      #   status_class = "foo-bar"
      #   button_classes = "btn btn-primary"
      #   ["Active", "status-active"]          (array element with hyphenated string)
      #   ["Cancelled", "status-cancelled"]
      #
      # Rule: any double- or single-quoted string containing at least one
      # hyphen is unambiguously a string value (not a Ruby identifier), so
      # we can safely extract it as a potential class name.
      #
      # Pattern 1: variable ending in _class/_classes/_style/_css = "value"
      DYNAMIC_CLASS_VAR = /\b\w+_(?:class(?:es)?|style|css)\s*=\s*["']([^"'\n]+)["']/
      #
      # Pattern 2: any quoted string with hyphens in array/tuple context
      # e.g. ["Active", "status-active"] — the hyphenated strings are CSS classes
      HYPHENATED_STRING = /["']([a-zA-Z][a-zA-Z0-9]*(?:-[a-zA-Z0-9]+)+)["']/

      # ── Ruby / Stimulus string literals ─────────────────────────────────
      # Any double-quoted string that looks like a space-separated class list
      JS_ADD_CLASS      = /(?:classList\.add|classList\.toggle|classList\.replace)\s*\(\s*["']([^"']+)["']/
      JS_REMOVE_CLASS   = /(?:classList\.remove)\s*\(\s*["']([^"']+)["']/
      RUBY_STRING_CLASSES = /["']([a-zA-Z][a-zA-Z0-9_-]*(?:\s+[a-zA-Z][a-zA-Z0-9_-]*)*)[\"']/

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

        if ext == ".erb" || base.end_with?(".html.erb")
          found.merge extract_erb(content)
        end

        if ext == ".haml" || base.end_with?(".html.haml")
          found.merge extract_haml(content)
        end

        if ext == ".slim" || base.end_with?(".html.slim")
          found.merge extract_slim(content)
        end

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
          stripped = chunk.gsub(/<%.*?%>/m, " ")
          stripped.scan(/["']([^"']+)["']/) { |m| found.merge tokenize(m[0]) }
        end

        # ── v0.2.1: Dynamic class variable detection ──────────────────────
        # Detects: status_class = "foo-bar" or button_classes = "btn btn-primary"
        found.merge extract_dynamic_class_vars(content)

        found
      end

      def extract_haml(content)
        found = Set.new

        content.scan(HAML_IMPLICIT) do |m|
          m[0].split(".").reject(&:empty?).each do |cls|
            found << cls if valid_class?(cls)
          end
        end

        content.scan(HAML_HASH_CLASS) { |m| found.merge tokenize(m[0]) }
        content.scan(RUBY_CLASS_KV)   { |m| found.merge tokenize(m[0]) }

        # v0.2.1: detect dynamic class vars in HAML Ruby blocks too
        found.merge extract_dynamic_class_vars(content)

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

        # v0.2.1: detect dynamic class vars in Slim Ruby blocks too
        found.merge extract_dynamic_class_vars(content)

        found
      end

      def extract_ruby(content)
        found = Set.new

        content.scan(RUBY_CLASS_KV)   { |m| found.merge tokenize(m[0]) }
        content.scan(RUBY_CLASS_ARRAY) { |m| found.merge tokenize(m[0].gsub(/["',]/, " ")) }

        content.scan(RUBY_STRING_CLASSES) do |m|
          tokens = tokenize(m[0])
          found.merge(tokens) if tokens.all? { |t| valid_class?(t) }
        end

        # v0.2.1: detect dynamic class vars in Ruby component files
        found.merge extract_dynamic_class_vars(content)

        found
      end

      def extract_js_classes(content)
        found = Set.new
        content.scan(JS_ADD_CLASS)    { |m| found.merge tokenize(m[0]) }
        content.scan(JS_REMOVE_CLASS) { |m| found.merge tokenize(m[0]) }
        found
      end

      # ── v0.2.1: Smart dynamic class variable extraction ──────────────────
      #
      # Scans content for two patterns:
      #
      # 1. Variables named *_class, *_classes, *_style, *_css assigned a string:
      #      status_class = "foo-bar"        => extracts "foo-bar"
      #      button_classes = "btn btn-sm"   => extracts "btn", "btn-sm"
      #
      # 2. Any quoted string containing a hyphen (unambiguous: Ruby variable
      #    names cannot contain hyphens, so hyphenated quoted strings MUST be
      #    string values, never variable names):
      #      ["Active", "status-active"]     => extracts "status-active"
      #      ["Cancelled", "status-cancelled"] => extracts "status-cancelled"
      #
      # This directly solves the false-positive problem where classes like
      # status-approved, status-cancelled, status-requested were flagged as
      # ghost classes because they were assigned to a variable (status_class)
      # and used via <%= status_class %> interpolation.
      def extract_dynamic_class_vars(content)
        found = Set.new

        # Pattern 1: *_class/*_classes variable assignments
        content.scan(DYNAMIC_CLASS_VAR) do |m|
          tokenize(m[0]).each { |cls| found << cls if valid_class?(cls) }
        end

        # Pattern 2: hyphenated string literals (unambiguously CSS class values)
        content.scan(HYPHENATED_STRING) do |m|
          cls = m[0].strip
          found << cls if valid_class?(cls)
        end

        found
      end

      # ── Helpers ───────────────────────────────────────────────────────────

      def tokenize(raw)
        return Set.new if raw.nil?

        raw
          .gsub(/["']/, " ")
          .split(/[\s,]+/)
          .map { |t| t.strip.delete_prefix(".") }
          .reject(&:empty?)
          .reject { |t| t.include?("<%") || t.include?('#{') }
          .select { |t| valid_class?(t) }
          .to_set
      end

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
