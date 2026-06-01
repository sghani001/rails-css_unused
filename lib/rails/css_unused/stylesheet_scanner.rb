# frozen_string_literal: true

module Rails
  module CssUnused
    # Extracts class selectors from CSS/SCSS/Sass files (static parse, no full AST).
    class StylesheetScanner
      # .class-name, .foo.bar, div.class — capture class tokens after dots
      CLASS_SELECTOR_PATTERN = /\.([a-zA-Z_][\w-]*(?:--[\w-]+)?)/

      # Strip comments before matching
      BLOCK_COMMENT = %r{/\*.*?\*/}m
      LINE_COMMENT = %r{//[^\n]*}

      def initialize(root:, config: CssUnused.configuration)
        @root = Pathname(root)
        @config = config
      end

      def defined_classes
        classes = Set.new
        each_stylesheet_file { |content| classes.merge(extract_from(strip_comments(content))) }
        classes.subtract(normalized_ignore_list)
        classes
      end

      private

      def each_stylesheet_file
        search_roots = @config.stylesheet_paths + @config.javascript_paths
        extensions = Configuration::CSS_EXTENSIONS

        search_roots.each do |relative|
          dir = @root.join(relative)
          next unless dir.directory?

          Dir.glob(dir.join("**", "*")).each do |file|
            path = Pathname(file)
            next unless path.file?
            next unless extensions.include?(path.extname)

            yield read_file(path)
          end
        end
      end

      def read_file(path)
        path.read(encoding: Encoding::UTF_8)
      rescue ArgumentError
        path.read
      end

      def strip_comments(css)
        css.gsub(BLOCK_COMMENT, "").gsub(LINE_COMMENT, "")
      end

      def extract_from(css)
        found = Set.new
        css.scan(CLASS_SELECTOR_PATTERN) do |match|
          class_name = match.is_a?(Array) ? match[0] : match
          next if skip_selector?(class_name, css)

          found << class_name
        end
        found
      end

      def skip_selector?(class_name, _css)
        return true if pseudo_or_utility_noise?(class_name)

        @config.ignore_selectors_matching.any? { |pattern| class_name.match?(pattern) }
      end

      def pseudo_or_utility_noise?(name)
        %w[import media charset namespace].include?(name)
      end

      def normalized_ignore_list
        @config.ignore_classes.map(&:to_s)
      end
    end
  end
end
