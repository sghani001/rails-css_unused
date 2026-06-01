# frozen_string_literal: true

module Rails
  module CssUnused
    # Extracts CSS class names referenced in Rails views and components via regex.
    # Dynamic classes (ERB interpolation) are only partially detected — see README.
    class ViewScanner
      # class="foo bar", class='foo', class: "foo", class: 'foo', class: %w[foo bar]
      CLASS_ATTRIBUTE_PATTERN = /
        class\s*=\s*["']([^"']+)["']
        |
        class:\s*["']([^"']+)["']
        |
        class:\s*%w\[\s*([^\]]+)\]
        |
        class:\s*\[\s*([^\]]+)\]
      /ix

      # HAML: .foo.bar or %div.foo
      HAML_CLASS_PATTERN = /\.([a-zA-Z_][\w-]*)/

      # Tailwind-style @apply or data-class rarely; common helper: tag.div class: "x"
      TAG_HELPER_CLASS_PATTERN = /(?:^|\s)class:\s*["']([^"']+)["']/m

      def initialize(root:, config: CssUnused.configuration)
        @root = Pathname(root)
        @config = config
      end

      def used_classes
        classes = Set.new
        each_view_file { |path, content| classes.merge(extract_from(content, path)) }
        classes.subtract(normalized_ignore_list)
        classes
      end

      private

      def each_view_file
        paths = @config.view_paths + @config.component_paths
        extensions = (Configuration::VIEW_EXTENSIONS + Configuration::COMPONENT_EXTENSIONS).uniq

        paths.each do |relative|
          dir = @root.join(relative)
          next unless dir.directory?

          Dir.glob(dir.join("**", "*")).each do |file|
            path = Pathname(file)
            next unless path.file?
            next unless extensions.include?(path.extname) || compound_extension?(path)

            yield path, path.read(encoding: Encoding::UTF_8)
          rescue ArgumentError
            yield path, path.read
          end
        end
      end

      def compound_extension?(path)
        name = path.basename.to_s
        Configuration::VIEW_EXTENSIONS.any? { |ext| name.end_with?(ext) }
      end

      def extract_from(content, path)
        found = Set.new
        content.scan(CLASS_ATTRIBUTE_PATTERN).flatten.compact.each do |chunk|
          found.merge(tokenize_class_value(chunk))
        end
        content.scan(TAG_HELPER_CLASS_PATTERN) { |m| found.merge(tokenize_class_value(m[0])) }
        if haml_file?(path)
          content.scan(HAML_CLASS_PATTERN) { |m| found << m[0] unless haml_false_positive?(m[0]) }
        end
        found.merge(extract_erb_interpolated_classes(content))
        found
      end

      def haml_file?(path)
        path.extname == ".haml" || path.to_s.end_with?(".html.haml")
      end

      # Skip decimal numbers like .5 in HAML (rare in class position but possible in CSS snippets)
      def haml_false_positive?(token)
        token.match?(/\A\d/)
      end

      def tokenize_class_value(raw)
        raw
          .gsub(/['"]/, " ")
          .split(/[\s,]+/)
          .map { |t| t.strip.sub(/\A\./, "") }
          .reject(&:empty?)
          .reject { |t| t.include?("<%") || t.include?('#{') }
          .select { |t| valid_class_token?(t) }
      end

      def valid_class_token?(token)
        token.match?(/\A[a-zA-Z_][\w-]*\z/) || token.match?(/\A[a-zA-Z_][\w-]*--[\w-]+\z/)
      end

      # Picks up literal segments inside ERB-interpolated class attributes when present.
      def extract_erb_interpolated_classes(content)
        found = Set.new
        content.scan(/class\s*=\s*["'][^"']*<%=[^%]+%>[^"']*["']/m) do
          literal = Regexp.last_match(0)
          literal.gsub(/<%.*?%>/m, " ").scan(/["']([^"']+)["']/) do |part|
            found.merge(tokenize_class_value(part[0]))
          end
        end
        found
      end

      def normalized_ignore_list
        @config.ignore_classes.map(&:to_s)
      end
    end
  end
end
