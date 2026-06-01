# Changelog

## [0.2.0] - 2026-06-02

### 🔧 Fixed
- **Extension noise eliminated** — `.png`, `.css`, `.jpg`, `.js` etc. no longer appear as ghost classes
- **At-rule noise eliminated** — `@charset`, `@import`, `@keyframes` tokens no longer pollute the class list
- **`:not()` false positives fixed** — `.foo` inside `:not(.foo)` is no longer treated as a new definition
- **Double-scanning removed** — `ViewScanner` and `StylesheetScanner` were each instantiated twice in `print_summary`, wasting time and producing wrong counts

### ✨ Added
- **Source file attribution** — `show_source_files: true` shows which stylesheet each ghost comes from
- **CI mode** — `fail_on_unused: true` + `rake css_unused:ci` exits with code 1 on any ghost
- **`rake css_unused:report_verbose`** — shows ghost classes with source file inline
- **HAML & Slim support** — proper extraction of `.foo.bar` shorthand selectors
- **Slim template support** — `div.foo` class shorthand
- **Ruby component support** — scans ViewComponent `.rb` files for `class:` attributes
- **Stimulus / JS support** — `classList.add("foo")` calls detected as used classes
- **ERB dynamic class extraction** — `class="<%= cond ? 'a' : 'b' %>"` — static string parts extracted
- **`ignore_patterns`** — regex-based ignore list (e.g. `/\Ajs-/`, `/\Ais-/`)
- **`scan_javascript_for_classes`** — opt-in JS scanning for dynamically applied classes
- **`scan_ruby_components`** — opt-in scanning of `.rb` component files
- **Colour terminal output** — red/green/grey ANSI when outputting to a TTY
- **BEM double-underscore selectors** — `block__element--modifier` handled correctly

### 🗑️ Removed
- Confusing `stylesheet_scanner.rb` noise filter that used a hardcoded `%w[import media charset...]` list (replaced with proper context-aware skip logic)

## [0.1.0] - 2026-05-01
- Initial release
