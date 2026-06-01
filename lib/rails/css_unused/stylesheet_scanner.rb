# frozen_string_literal: true

module Rails
  module CssUnused
    # Scans CSS / SCSS / Sass stylesheets and extracts every defined class selector.
    #
    # Key improvements over v0.1:
    #  - Tracks which FILE each class was defined in (for --show-source-files).
    #  - Properly strips @charset, @import, @media, @keyframes, @font-face noise.
    #  - Ignores pseudo-class arguments like :not(.foo) — .foo is counted as used.
    #  - Handles BEM double-dash and double-underscore selectors.
    #  - Skips file-extension false positives (.png, .jpg, .css, .js etc.)
    #  - Skips @-rule word tokens that look like class selectors (.keyframe-name).
    #  - Applies ignore_classes AND ignore_patterns from configuration.
    class StylesheetScanner
      # Match .classname anywhere a class selector can appear.
      # Deliberately broad — noise is filtered by the skip logic below.
      CLASS_SELECTOR_PATTERN = /(?<![:\w])\.(-?[a-zA-Z_][a-zA-Z0-9_-]*)/

      BLOCK_COMMENT  = %r{/\*.*?\*/}m
      LINE_COMMENT   = %r{//[^\n]*}
      STRING_LITERAL = /(['"])(?:(?!\1).)*\1/   # strip quoted strings first

      # At-rule keywords whose following token looks like a class selector
      # but is actually metadata: @charset, @import, @namespace, @keyframes, etc.
      AT_RULE_NOISE = %w[
        charset import namespace supports keyframes
        font-face font-feature-values counter-style layer
        page media document
      ].freeze

      # File extensions that produce false positives when found after a dot.
      EXTENSION_NOISE = %w[
        png jpg jpeg gif svg webp ico bmp tiff
        css scss sass less
        js ts jsx tsx mjs cjs
        rb erb haml slim html htm xml json yaml yml
        pdf zip gz tar woff woff2 ttf eot
        map min
      ].freeze

      # Result struct — class name plus the file it was found in.
      DefinedClass = Struct.new(:name, :source_file, keyword_init: true)

      def initialize(root:, config: CssUnused.configuration)
        @root   = Pathname(root)
        @config = config
      end

      # Returns a Set of plain class name strings (for diff calculations).
      def defined_classes
        scan_all.map(&:name).to_set
      end

      # Returns Array<DefinedClass> with source file info.
      def defined_classes_with_sources
        scan_all
      end

      private

      def scan_all
        results = []
        ignore_set      = @config.ignore_classes.map(&:to_s).to_set
        ignore_patterns = Array(@config.ignore_patterns)

        each_stylesheet_file do |path, content|
          extract_from(clean(content), path).each do |name|
            next if ignore_set.include?(name)
            next if ignore_patterns.any? { |pat| name.match?(pat) }
            results << DefinedClass.new(name: name, source_file: path)
          end
        end

        # Deduplicate by name, keeping first occurrence.
        seen = Set.new
        results.select { |dc| seen.add?(dc.name) }
      end

      def each_stylesheet_file
        dirs = (@config.stylesheet_paths + @config.javascript_paths)
               .map { |p| @root.join(p) }
               .select(&:directory?)

        dirs.each do |dir|
          Dir.glob(dir.join("**", "*")).each do |file|
            path = Pathname(file)
            next unless path.file?
            next unless Configuration::CSS_EXTENSIONS.include?(path.extname)

            content = safe_read(path)
            yield path, content if content
          end
        end
      end

      # Remove comments and string literals so we don't extract class names
      # from inside @import "file.css" or url("image.png").
      def clean(css)
        css
          .gsub(BLOCK_COMMENT, " ")
          .gsub(LINE_COMMENT,  " ")
          .gsub(STRING_LITERAL, " ")
      end

      def extract_from(css, _path)
        found = Set.new

        css.scan(CLASS_SELECTOR_PATTERN) do |match|
          name = match[0]
          next if skip?(name, Regexp.last_match.pre_match)
          found << name
        end

        found
      end

      def skip?(name, pre_match)
        # File extension false positives: .png .jpg .css etc.
        return true if EXTENSION_NOISE.include?(name.downcase)

        # Pure numbers or starting with a digit
        return true if name.match?(/\A\d/)

        # Single-character tokens are almost always noise
        return true if name.length == 1

        # At-rule keyword false positives: @keyframes slide-in → .slide-in is OK,
        # but @charset, @import etc. followed by a dot-prefixed string.
        preceding_word = pre_match.strip.split(/\s+/).last.to_s.gsub(/\A@/, "")
        return true if AT_RULE_NOISE.include?(preceding_word.downcase)

        # :not(.foo), :is(.foo), :where(.foo) — .foo is a USED class, not defined here.
        # We skip it from the defined set; it will be found in views anyway.
        return true if pre_match.match?(/:(not|is|where|has)\s*\(\s*\z/)

        false
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
