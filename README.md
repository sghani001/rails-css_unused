# rails-css_unused

Find **ghost CSS classes** in your Rails app: selectors that exist in your stylesheets but never show up in views or ViewComponents.

Pure static analysis — no browser, no headless Chrome. Built for the usual Rails paths (`app/views`, `app/components`, `app/assets/stylesheets`).

## Install

Add to your Gemfile:

```ruby
gem "rails-css_unused", group: :development
```

```bash
bundle install
```

## Usage

```bash
bin/rails css_unused:report
# or
bin/rails css_unused:ghosts
```

Example output:

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
  ...
```

## What it scans

| Source | Paths (default) |
|--------|-----------------|
| Views | `app/views` — `.html.erb`, `.html.haml`, `.haml`, `.erb`, `.slim` |
| Components | `app/components` — same extensions |
| Styles | `app/assets/stylesheets`, `app/assets/builds` — `.css`, `.scss`, `.sass` |
| JS CSS | `app/javascript` — same stylesheet extensions |

### Class detection in templates

- `class="foo bar"`
- `class: "foo"`, `class: 'foo'`
- `class: %w[foo bar]`, `class: ["foo", "bar"]`
- `tag.div ..., class: "foo"`
- Basic HAML `.class-name` segments

## Configuration

```ruby
# config/initializers/rails_css_unused.rb
Rails::CssUnused.configure do |config|
  config.ignore_classes += %w[active hidden]
  config.stylesheet_paths << "vendor/assets/stylesheets"
  config.view_paths << "app/views/admin"
end
```

Or via `config/application.rb` (optional):

```ruby
config.rails_css_unused = ActiveSupport::OrderedOptions.new
config.rails_css_unused.ignore_classes = %w[sr-only]
```

## Limitations (read this)

Static analysis cannot see everything:

- **Dynamic classes** — `class="<%= dynamic %>"` may be missed or only partially detected.
- **Tailwind / utility frameworks** — utilities are often generated at build time; many “ghost” hits are false positives unless you scan compiled `app/assets/builds` and ignore Tailwind layers.
- **JavaScript-added classes** — Stimulus, React, or `element.classList.add` are not scanned (extend `javascript_paths` only helps for CSS files in JS folders).
- **@extend / mixins** — SCSS may define classes only used inside other rules; review before deleting.

Treat the report as a **triage list**, not an automatic delete command.

## Programmatic API

```ruby
Rails::CssUnused.ghost_classes
# => ["orphan-widget", "legacy-banner", ...]

Rails::CssUnused.report
```

## Development

```bash
bundle install
ruby -Ilib -S rspec
```

Maintainers: see [PUBLISHING.md](PUBLISHING.md) for release checklist and RubyGems steps.

## License

MIT
