# rails-css_unused 🔍

**Find unused CSS classes in your Rails app — zero runtime overhead, smart dynamic class detection.**

[![Gem Version](https://img.shields.io/gem/v/rails-css_unused.svg)](https://rubygems.org/gems/rails-css_unused)
[![Downloads](https://img.shields.io/gem/dt/rails-css_unused.svg)](https://rubygems.org/gems/rails-css_unused)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
![Rails](https://img.shields.io/badge/Rails-7.0%2B-red)
![Ruby](https://img.shields.io/badge/Ruby-3.1%2B-red)
![Stable](https://img.shields.io/badge/stable-0.2.1-brightgreen)

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
| **Smart dynamic class variable detection** | ❌ | ✅ **v0.2.1** |
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

## What is a "ghost class"?

A ghost class is a CSS class that is:
- ✅ **Defined** in a `.css`, `.scss`, or `.sass` file
- ❌ **Never referenced** in any `.erb`, `.haml`, `.slim`, `.rb`, or `.js` file

Ghost classes add dead weight to your CSS bundle and confuse future developers.

---

## Smart Dynamic Class Detection (v0.2.1)

A common Rails pattern is to assign CSS class strings to a variable and render them via ERB interpolation:

```erb
<% status_label, status_class =
  if exam.cancelled?
    ["Cancelled", "status-cancelled"]
  elsif exam.approved?
    ["Approved", "status-approved"]
  elsif exam.request_approval?
    ["Requested approval", "status-requested"]
  else
    ["Draft", "status-draft"]
  end %>

<span class="status-pill <%= status_class %>"><%= status_label %></span>
```

Before v0.2.1, `status-cancelled`, `status-approved`, `status-requested`, and `status-draft` were all reported as **ghost classes** — false positives. From v0.2.1 onwards, the scanner automatically detects them as used via two smart rules:

### Rule 1 — Variable name heuristic
Any string assigned to a variable whose name ends in `_class`, `_classes`, `_style`, or `_css` is treated as a CSS class value:

```ruby
status_class   = "status-active"        # ✅ status-active detected
button_classes = "btn btn-primary"      # ✅ btn, btn-primary detected
card_style     = "card-elevated"        # ✅ card-elevated detected
nav_css        = "navbar-fixed"         # ✅ navbar-fixed detected
```

### Rule 2 — Hyphenated string literal heuristic
Ruby variable names **cannot contain hyphens** — so any quoted string containing a hyphen is unambiguously a string *value*, never a variable name. The scanner exploits this to safely extract class names:

```ruby
["Cancelled", "status-cancelled"]   # ✅ status-cancelled extracted (hyphen = string value)
["Approved",  "status-approved"]    # ✅ status-approved extracted
"btn--primary"                      # ✅ BEM modifier extracted
"card__header"                      # ✅ BEM element extracted
```

These two rules together eliminate the most common source of false positives in Rails apps that use server-side conditional class assignment — **no `ignore_patterns` workarounds needed**.

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

## Supported Patterns

The scanner detects CSS classes from all of these patterns:

```erb
<%# Standard HTML %>
<div class="foo bar baz">
<div class='foo bar'>

<%# Ruby helpers %>
<%= tag.div class: "btn btn-primary" %>
<%= content_tag :div, class: "card" %>
<%= tag.div class: ["card", "card-body"] %>
<%= tag.div class: %w[flex items-center] %>

<%# Dynamic interpolation (static parts extracted) %>
<div class="prefix-<%= var %> suffix">
<div class="<%= condition ? 'on' : 'off' %>">

<%# v0.2.1: Dynamic class variable assignment %>
<% status_class = "status-active" %>
<% button_classes = "btn btn-sm" %>
<span class="<%= status_class %>">

<%# v0.2.1: Conditional multi-branch assignment %>
<% badge_class = exam.passed? ? "badge-success" : "badge-danger" %>
```

```haml
-# HAML
.foo.bar
%div.foo.bar
%span{ class: "foo bar" }
```

```slim
/ Slim
div.foo.bar
.foo.bar
```

```ruby
# ViewComponent / Phlex
render MyComponent.new(class: "card card-body")
tag.div(class: "flex items-center")
```

```javascript
// Stimulus JS
this.element.classList.add("is-loading")
this.element.classList.toggle("hidden")
```

---

## Reducing false positives

| Situation | Solution |
|-----------|----------|
| `class="status-#{record.state}"` (pure string interpolation) | Add `ignore_patterns << /\Astatus-/` |
| `<% cls = condition ? "foo-a" : "foo-b" %>` | **v0.2.1: auto-detected** ✅ |
| `["Label", "css-class-name"]` in conditionals | **v0.2.1: auto-detected** ✅ |
| JS-only classes (e.g. `js-modal-open`) | Auto-ignored via `ignore_patterns` default |
| Third-party component classes | Add prefix pattern to `ignore_patterns` |
| Turbo / Stimulus data-action targets | Add to `ignore_classes` |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for full version history.

## Contributing

Bug reports and pull requests welcome at https://github.com/sghani001/rails-css_unused.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Write tests for your changes
4. Run `bundle exec rspec`
5. Open a Pull Request

## License

MIT — © Syed Ghani
