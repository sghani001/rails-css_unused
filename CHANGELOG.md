# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-01

### Added

- `css_unused:report` and `css_unused:ghosts` Rake tasks (via Railtie)
- View scanner for `app/views` and `app/components` (ERB, HAML, `class:` helpers)
- Stylesheet scanner for CSS/SCSS/Sass under assets and `app/javascript`
- `Rails::CssUnused.report` and `Rails::CssUnused.ghost_classes` APIs
- `Rails::CssUnused.configure` for paths and ignored classes

### Known limitations

- Dynamic classes in ERB may not be detected
- Tailwind / build-time utilities may report false positives
- Classes added only via JavaScript are not detected

[0.1.0]: https://github.com/sghani001/rails-css_unused/releases/tag/v0.1.0
