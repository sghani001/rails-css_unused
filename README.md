# rails-css_unused

**Find unused CSS classes in your Rails app — zero runtime overhead, zero false positives from file extensions or at-rules.**

[![Gem Version](https://badge.fury.io/rb/rails-css_unused.svg)](https://rubygems.org/gems/rails-css_unused)

---

## Why this gem?

| Feature | deadweight | rails-css_unused |
|---------|-----------|-----------------|
| Maintained | ❌ abandoned | ✅ |
| Rails 7+ | ❌ | ✅ |
| Static analysis (no server needed) | ❌ needs running server | ✅ |
| BEM selector support | ❌ | ✅ |
| HAML / Slim support | ❌ | ✅ |
| ViewComponent / Phlex support | ❌ | ✅ |
| Stimulus JS class detection | ❌ | ✅ |
| ERB dynamic class extraction | ❌ | ✅ |
| Source file attribution | ❌ | ✅ |
| CI exit code support | ❌ | ✅ |
| Regex ignore patterns | ❌ | ✅ |
| Extension false-positive protection | ❌ | ✅ |

---

## Installation

```ruby
# Gemfile
gem "rails-css_unused", group: :development
```

```bash
bundle install
```

---

## Usage

```bash
# Standard report
bundle exec rake css_unused:report

# With source file for each ghost class
bundle exec rake css_unused:report_verbose

# CI — exits with code 1 if any ghost classes found
bundle exec rake css_unused:ci
```

### Programmatic usage

```ruby
# List ghost class names
Rails::CssUnused.ghost_classes  # => ["old-btn", "legacy-card"]

# Full report to custom IO
Rails::CssUnused.report(output: File.open("report.txt", "w"))
```

---

## Configuration

Create `config/initializers/css_unused.rb`:

```ruby
Rails::CssUnused.configure do |config|
  # Paths to scan (relative to Rails.root)
  config.stylesheet_paths = %w[app/assets/stylesheets app/assets/builds]
  config.view_paths       = %w[app/views]
  config.component_paths  = %w[app/components]
  config.javascript_paths = %w[app/javascript]

  # Exact class names to never flag as ghost
  config.ignore_classes = %w[
    clearfix sr-only visually-hidden
    active disabled selected
  ]

  # Regex patterns — any matching class is ignored
  config.ignore_patterns = [
    /\Ajs-/,    # JS hook classes  (js-submit-btn)
    /\Ais-/,    # state classes    (is-active, is-open)
    /\Ahas-/,   # state classes    (has-error)
  ]

  # Detect classes added via classList.add() in JS files
  config.scan_javascript_for_classes = true

  # Scan ViewComponent .rb files for class: attributes
  config.scan_ruby_components = true

  # Show which stylesheet each ghost class came from
  config.show_source_files = false

  # Exit with code 1 in CI when ghosts are found
  config.fail_on_unused = false
end
```

---

## What is a "ghost class"?

A ghost class is a CSS class that is:
- ✅ **Defined** in a `.css`, `.scss`, or `.sass` file
- ❌ **Never referenced** in any `.erb`, `.haml`, `.slim`, `.rb`, or `.js` file

Ghost classes add dead weight to your CSS bundle and confuse future developers.

---

## Reducing false positives

Some classes are legitimately hard to detect statically:

| Situation | Solution |
|-----------|----------|
| `class="status-#{record.state}"` | Add `ignore_patterns << /\Astatus-/` |
| JS-only classes (e.g. `js-modal-open`) | Add `ignore_patterns << /\Ajs-/` or enable `scan_javascript_for_classes` |
| Third-party component classes | Add prefix pattern to `ignore_patterns` |
| Turbo / Stimulus data-action targets | Add to `ignore_classes` |

---

## License

MIT
