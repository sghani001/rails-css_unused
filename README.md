# rails-css_unused 👻

> Find ghost CSS classes in your Rails app — pure static analysis, zero browser automation.

[![Gem Version](https://img.shields.io/gem/v/rails-css_unused.svg)](https://rubygems.org/gems/rails-css_unused)
[![Downloads](https://img.shields.io/gem/dt/rails-css_unused.svg)](https://rubygems.org/gems/rails-css_unused)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
![Rails](https://img.shields.io/badge/Rails-7.0%2B-red)
![Ruby](https://img.shields.io/badge/Ruby-3.1%2B-red)
![Stable](https://img.shields.io/badge/stable-0.1.0-brightgreen)

**rails-css_unused** is a lightweight Rails gem that finds **ghost classes** — CSS selectors defined in your stylesheets but never referenced in views or ViewComponents. Unlike [PurgeCSS](https://purgecss.com/) or Tailwind’s JIT (which optimize *build output*), rails-css_unused is built for **Rails project hygiene**: a simple Rake report that answers *“which custom classes in `app/assets` are dead code?”* without headless Chrome, without a production build, and without sending your templates anywhere.

---

## Compatibility

| | Version |
|---|---|
| Ruby | >= 3.1 |
| Rails | >= 7.0 (via `railties`) |
| Templates | ERB, HAML, Slim, ViewComponent-style paths |
| Stylesheets | `.css`, `.scss`, `.sass` |

---

## Why rails-css_unused over other tools?

| | PurgeCSS / Tailwind JIT | rails-css_unused |
|---|---|---|
| Focus | Shrink final CSS bundle | Audit *your* Rails templates vs *your* styles |
| Setup | PostCSS / build pipeline | `bin/rails css_unused:report` |
| Rails paths | Manual content globs | Defaults: `app/views`, `app/components`, `app/assets` |
| Browser | Not required | Not required |
| ViewComponent | Extra config | `app/components` scanned by default |
| Output | Rewrites CSS file | Read-only report (safe triage) |
| Dynamic ERB classes | Build-dependent | Documented limitations; `ignore_classes` |

---

## Installation

```ruby
gem "rails-css_unused", "~> 0.1.0", group: :development
```

```bash
bundle install
```

No migrations. No JavaScript snippet. No cookies.

---

## Quick start

### 1. Add the gem (development group recommended)

```ruby
# Gemfile
gem "rails-css_unused", group: :development
```

### 2. Run the report

```bash
bin/rails css_unused:report
# alias:
bin/rails css_unused:ghosts
```

### 3. Review ghost classes

```
rails-css_unused — Ghost Class Report
========================================
Project root: /path/to/myapp
Classes in stylesheets: 142
Classes referenced in views: 118
Ghost classes (in CSS, not in views): 24

Ghost classes:
  legacy-banner
  orphan-widget
  old-checkout-step
  ...
```

Delete or refactor styles **after** you confirm a class is truly unused (see [Limitations](#limitations)).

---

## What it scans

| Source | Default paths | Extensions |
|--------|---------------|------------|
| Views | `app/views` | `.html.erb`, `.html.haml`, `.haml`, `.erb`, `.slim` |
| Components | `app/components` | same as views |
| Stylesheets | `app/assets/stylesheets`, `app/assets/builds` | `.css`, `.scss`, `.sass` |
| JS-held CSS | `app/javascript` | `.css`, `.scss`, `.sass` |

### Class detection in templates

- `class="foo bar"`
- `class: "foo"`, `class: 'foo'`
- `class: %w[foo bar]`, `class: ["foo", "bar"]`
- `tag.span "Hi", class: "greeting-label"`
- Basic HAML `.class-name` segments

---

## Configuration

```ruby
# config/initializers/rails_css_unused.rb
Rails::CssUnused.configure do |config|
  config.ignore_classes += %w[active hidden is-loading]
  config.stylesheet_paths << "vendor/assets/stylesheets"
  config.view_paths << "app/views/admin"
  config.component_paths << "app/views/components"
  config.javascript_paths << "app/frontend/styles"
end
```

Optional hook in `config/application.rb`:

```ruby
config.rails_css_unused = ActiveSupport::OrderedOptions.new
config.rails_css_unused.ignore_classes = %w[sr-only visually-hidden]
```

### Default ignored classes

`clearfix`, `sr-only`, `visually-hidden` — extend via `ignore_classes`.

---

## Programmatic API

```ruby
Rails::CssUnused.ghost_classes
# => ["orphan-widget", "legacy-banner", ...]

Rails::CssUnused.report
# prints summary to STDOUT; returns array of ghost structs

report = Rails::CssUnused::Report.new(root: Rails.root)
report.ghost_classes.map(&:class_name)
# => ["orphan-widget", ...]
```

Use in CI (example — fail if too many ghosts slip in):

```ruby
# lib/tasks/css_unused_ci.rake
namespace :css_unused do
  task ci_check: :environment do
    ghosts = Rails::CssUnused.ghost_classes
    abort "Too many ghost CSS classes (#{ghosts.size}). Run: bin/rails css_unused:report" if ghosts.size > 50
  end
end
```

---

## Comparison with other approaches

| Approach | What it does | rails-css_unused advantage |
|----------|--------------|----------------------------|
| **Manual grep** | Tedious, easy to miss HAML / `class:` helpers | Rails-aware paths and patterns |
| **PurgeCSS** | Removes unused rules at build time | Non-destructive audit; no PostCSS required |
| **Tailwind CLI** | Scans utilities for compilation | Targets *custom* CSS left in Rails assets |
| **Chrome Coverage** | Runtime, needs browsing every page | Static; runs in CI without a browser |
| **stylelint** | Lint rules, not usage across views | Cross-folder view ↔ stylesheet diff |

---

## Limitations

Static analysis cannot see everything. Treat the report as a **triage list**, not an automatic delete command.

| Case | Behavior |
|------|----------|
| **Dynamic ERB** — `class="<%= status %>"` | May be missed or only partially detected |
| **Tailwind / utilities** | Build-time classes → false positives; scan `app/assets/builds`, tune `ignore_classes` |
| **JS-only classes** — Stimulus, React | Not scanned (only CSS *files* under `javascript_paths`) |
| **SCSS `@extend` / mixins** | Class may exist only inside generated CSS |
| **Third-party gem CSS** | Add gem stylesheet paths via `stylesheet_paths` or ignore |

---

## API reference

| Method / task | Description |
|---------------|-------------|
| `bin/rails css_unused:report` | Print ghost class summary to STDOUT |
| `bin/rails css_unused:ghosts` | Alias for `report` |
| `Rails::CssUnused.report` | Print report; returns ghost structs |
| `Rails::CssUnused.ghost_classes` | `Array<String>` of unused class names |
| `Rails::CssUnused.configure { ... }` | Set paths, `ignore_classes`, etc. |
| `Rails::CssUnused::ViewScanner#used_classes` | Classes found in views/components |
| `Rails::CssUnused::StylesheetScanner#defined_classes` | Classes found in stylesheets |
| `Rails::CssUnused::Report#ghost_classes` | `defined - used` as structs |

### Configuration options

| Option | Default | Description |
|--------|---------|-------------|
| `view_paths` | `["app/views"]` | Directories to scan for templates |
| `component_paths` | `["app/components"]` | ViewComponent (or similar) templates |
| `stylesheet_paths` | `app/assets/stylesheets`, `app/assets/builds` | CSS sources |
| `javascript_paths` | `["app/javascript"]` | CSS/SCSS files colocated with JS |
| `ignore_classes` | `clearfix`, `sr-only`, `visually-hidden` | Always excluded from ghost list |
| `ignore_selectors_matching` | `[]` | Regex list to skip selector names |

---

## Development

```bash
bundle install
ruby -Ilib -S rspec
```

Maintainers: see [PUBLISHING.md](PUBLISHING.md) for the release checklist and RubyGems steps.

---

## Contributing

Bug reports and pull requests are welcome at https://github.com/sghani001/rails-css_unused.

---

## License

MIT — © Syed M. Ghani
