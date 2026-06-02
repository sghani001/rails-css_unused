# Changelog

## [0.2.1] - 2026-06-02

### Added
- **Smart dynamic class variable detection** — the scanner now automatically
  detects CSS class strings assigned to variables whose name ends in
  `_class`, `_classes`, `_style`, or `_css` (e.g. `status_class = "foo-bar"`).
- **Hyphenated string literal detection** — any quoted string containing a
  hyphen is now treated as a CSS class value. Since Ruby variable names
  cannot contain hyphens, hyphenated quoted strings are unambiguously string
  values, never identifiers. This eliminates false positives from patterns like:
  ```erb
  <% status_class =
    if exam.cancelled?
      ["Cancelled", "status-cancelled"]
    elsif exam.approved?
      ["Approved", "status-approved"]
    end %>
  <span class="status-pill <%= status_class %>">
  ```
  Classes like `status-cancelled`, `status-approved`, `status-requested`
  are now correctly detected as used without needing `ignore_patterns`.
- Dynamic class var detection also runs in HAML, Slim, and Ruby component files.

### Fixed
- False positives for dynamically assigned CSS classes used via ERB interpolation
  (e.g. `<%= status_class %>`, `<%= button_css %>`).

## [0.2.0] - 2026-05-31

### Added
- HAML and Slim template scanning
- ViewComponent and Phlex component support
- Stimulus controller JS class scanning (`classList.add`, `classList.toggle`)
- `scan_javascript_for_classes` config option
- `scan_ruby_components` config option
- `show_source_files` config option
- `fail_on_unused` config option for CI pipelines
- BEM class name support (`block__element--modifier`)
- ERB dynamic class attribute extraction (static parts from `class="<%= expr %>"`)
- `ignore_patterns` config for regex-based exclusions
- Spinner output during scanning

## [0.1.0] - 2026-05-15

### Added
- Initial release
- CSS/SCSS/SASS stylesheet scanning
- ERB view scanning (`class="..."`, `class: "..."`, `class: [...]`)
- Ghost class report with counts
- `ignore_classes` configuration
- `css_unused:report` rake task
