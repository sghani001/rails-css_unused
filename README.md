# rails-css_unused

[![Gem Version](https://img.shields.io/gem/v/rails-css_unused)](https://rubygems.org/gems/rails-css_unused)
[![GitHub](https://img.shields.io/github/stars/sghani001/rails-css_unused?style=social)](https://github.com/sghani001/rails-css_unused)

Find **ghost CSS classes** in your Rails app: selectors that exist in your stylesheets but never show up in views or ViewComponents.

Pure static analysis — no browser, no headless Chrome. Built for the usual Rails paths (`app/views`, `app/components`, `app/assets/stylesheets`).

## Requirements

- Ruby **>= 3.1**
- Rails **>= 7.0** (via `railties`)

## Installation

```ruby
# Gemfile
gem "rails-css_unused", group: :development
```

```bash
bundle install
```

Or install the gem directly (after it is published on RubyGems):

```bash
gem install rails-css_unused
```

During development of this gem itself, use a path install:

```ruby
gem "rails-css_unused", path: "../rails-css_unused", group: :development
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

Optional `config/application.rb` hook:

```ruby
config.rails_css_unused = ActiveSupport::OrderedOptions.new
config.rails_css_unused.ignore_classes = %w[sr-only]
```

## Limitations

Static analysis cannot see everything:

- **Dynamic classes** — `class="<%= dynamic %>"` may be missed or only partially detected.
- **Tailwind / utility frameworks** — utilities are often generated at build time; many “ghost” hits are false positives unless you scan compiled `app/assets/builds` and tune `ignore_classes`.
- **JavaScript-added classes** — Stimulus, React, or `element.classList.add` are not scanned.
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

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/sghani001/rails-css_unused).

Maintainers: see [PUBLISHING.md](PUBLISHING.md) for the release checklist and RubyGems publish steps.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
