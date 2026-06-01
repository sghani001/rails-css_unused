# Gem publication notes — rails-css_unused

Use this document for every release. Copy the **Release block** below, fill in the placeholders, and keep completed blocks at the bottom for history.

---

## Next step: publish 0.1.0 to RubyGems

GitHub is done (`main` pushed). Do this once, from the gem root:

```bash
cd D:\projects\rails-gems\rails-css_unused

# 1. Confirm tests and version
ruby -Ilib -S rspec
# version should be 0.1.0 in lib/rails/css_unused/version.rb

# 2. Sign in to RubyGems (one time per machine; use API key from https://rubygems.org/profile/api_keys)
gem signin

# 3. Build and inspect (README.md must appear in the file list)
gem build rails-css_unused.gemspec
gem contents rails-css_unused-0.1.0.gem | findstr README

# 4. Push (first publish claims the gem name)
gem push rails-css_unused-0.1.0.gem

# 5. Tag the release on GitHub
git tag -a v0.1.0 -m "Release 0.1.0"
git push origin v0.1.0
```

After push, verify:

- https://rubygems.org/gems/rails-css_unused
- `gem install rails-css_unused` in a test app
- Create a GitHub Release from tag `v0.1.0` and paste the `CHANGELOG.md` section for 0.1.0

**Note:** If MFA is enabled on your RubyGems account, `gem push` may ask for an OTP. The gemspec sets `rubygems_mfa_required` so future releases also require MFA.

---

## Pre-release checklist

- [ ] All intended changes are merged on the release branch
- [ ] `lib/rails/css_unused/version.rb` matches the tag you will publish
- [ ] `CHANGELOG.md` has an entry for this version (Added / Changed / Fixed / Removed)
- [ ] `README.md` reflects new or changed public API
- [ ] Tests pass locally (`ruby -Ilib -S rspec` or `bundle exec rspec`)
- [ ] No secrets, debug code, or accidental files in the gem package
- [ ] `gemspec` `files` list includes everything shipped (`lib/**`, `README.md`, `LICENSE.txt`, `CHANGELOG.md`)
- [ ] Dependencies and `required_ruby_version` are correct (`railties >= 7.0`, Ruby `>= 3.1.0`)
- [ ] Breaking changes are called out clearly in the changelog
- [x] `gemspec` `authors`, `email`, and `homepage` point to real maintainer / repo URLs
- [x] `README.md` is complete and included in the built `.gem` package

---

## How to publish (RubyGems)

1. **Bump version** in `lib/rails/css_unused/version.rb`.
2. **Update changelog** with date and summary of changes.
3. **Commit** version + changelog (only when you intend to release that commit).
4. **Build the gem** (from gem root):

   ```bash
   gem build rails-css_unused.gemspec
   ```

5. **Verify the package** (optional but recommended):

   ```bash
   gem unpack rails-css_unused-<version>.gem
   # Inspect: lib/rails/css_unused/*, tasks.rake, no spec/ or secrets
   ```

6. **Push to RubyGems** (requires `gem signin` once per machine):

   ```bash
   gem push rails-css_unused-<version>.gem
   ```

7. **Tag in git** (optional, recommended):

   ```bash
   git tag -a v<version> -m "Release <version>"
   git push origin v<version>
   ```

8. **GitHub release** (optional): create a release from the tag and paste the changelog section for that version.

---

## Release block (copy per version)

```markdown
## [<version>] - <YYYY-MM-DD>

### Summary
<One or two sentences: what this release is for and who it helps.>

### Added
- <New feature or API>

### Changed
- <Behavior change that is not a breaking fix>

### Fixed
- <Bug fix> (fixes #<issue> if applicable)

### Removed / Deprecated
- <Anything removed or scheduled for removal>

### Breaking changes
- <None, or describe migration steps>

### Known issues / limitations
- <Anything users should know; link to open issues if helpful>

### How we handle common concerns

| Concern | Approach in this gem |
|--------|----------------------|
| **Boot / Railtie** | Rake tasks loaded via `Rails::CssUnused::Railtie`; run with `bin/rails css_unused:report` |
| **Autoloading** | No engine; `lib/rails/css_unused.rb` required by Railtie / Rake `:environment` |
| **Database** | N/A — no DB, no migrations |
| **Async / jobs** | N/A — synchronous Rake task only |
| **Errors** | Missing dirs are skipped; invalid paths are not fatal |
| **Data growth** | N/A — read-only scan; no persistence |
| **Security / privacy** | No network calls; reads only local view/stylesheet files |

### Test plan (before publish)
- [ ] Fresh install in a minimal Rails app (or dummy app)
- [ ] `bin/rails css_unused:report` runs without error
- [ ] Ghost list matches manual spot-check on known dead CSS
- [ ] Regression for issues fixed in this release: #<ids>

### Publication
- [ ] `gem build` succeeded
- [ ] `gem push` completed
- [ ] Tag `v<version>` pushed
- [ ] Changelog visible on RubyGems / GitHub release
```

---

## RubyGems release description (short)

Paste into the RubyGems “Description” update or GitHub release body when you want a compact blurb:

```text
rails-css_unused <version>

Find ghost CSS classes in Rails apps with pure static analysis—no browser required.

Highlights:
- <bullet>
- <bullet>

See CHANGELOG.md for full details.
```

---

## Issue handling (generic playbook)

Use this when triaging before or after a release:

1. **Reproduce** — minimal app, gem version, Rails/Ruby versions from the reporter.
2. **Classify** — bug (fix in patch), enhancement (minor), breaking API (major + changelog).
3. **Fix scope** — smallest change that solves the root cause; avoid unrelated refactors in release PRs.
4. **Document** — README or changelog; link `fixes #N` in commit/PR when closing GitHub issues.
5. **Verify** — add or extend a test when behavior is non-trivial.
6. **Ship** — patch release unless semver major/minor is warranted.
7. **Follow-up** — if a workaround exists, note it under **Known issues** until the fix ships.

---

## Version policy (semver)

| Bump | When |
|------|------|
| **PATCH** (0.0.x) | Bug fixes, packaging, docs that don’t change API |
| **MINOR** (0.x.0) | New features, backward compatible |
| **MAJOR** (x.0.0) | Breaking API or behavior; migration guide required |

Pre-1.0: minor bumps may still break lightly; document anyway.

---

## Release history

### 0.1.0 — 2026-06-01 (draft — not yet published)

#### Summary

First public release. Statically finds CSS class selectors present in stylesheets but not referenced in Rails views or ViewComponents—no headless browser.

#### Added

- `bin/rails css_unused:report` and `css_unused:ghosts` Rake tasks
- `Rails::CssUnused::ViewScanner` — regex extraction from ERB/HAML-style templates
- `Rails::CssUnused::StylesheetScanner` — class selector extraction from CSS/SCSS/Sass
- `Rails::CssUnused.report` and `Rails::CssUnused.ghost_classes` Ruby API
- Configurable paths and `ignore_classes` via `Rails::CssUnused.configure`

#### Changed

- _(none — initial release)_

#### Fixed

- _(none — initial release)_

#### Removed / Deprecated

- _(none)_

#### Breaking changes

- None

#### Known issues / limitations

- Dynamic ERB class names may be missed or only partially detected
- Tailwind and other build-time utilities can produce false-positive “ghosts”
- JavaScript-added classes (Stimulus, React) are not scanned
- SCSS `@extend` / mixin-only classes may appear unused

#### How we handle common concerns

| Concern | Approach in this gem |
|--------|----------------------|
| **Boot / Railtie** | Rake tasks loaded via `Rails::CssUnused::Railtie`; run with `bin/rails css_unused:report` |
| **Autoloading** | No engine; scanners live under `lib/rails/css_unused/` |
| **Database** | N/A |
| **Async / jobs** | N/A — synchronous Rake task |
| **Errors** | Skips missing directories; does not mutate files |
| **Data growth** | N/A — no stored state |
| **Security / privacy** | Local filesystem reads only; no external HTTP |

#### Test plan (before publish)

- [ ] `ruby -Ilib -S rspec` passes
- [ ] `gem build rails-css_unused.gemspec` succeeds
- [ ] Path install in a Rails 7+ app: `gem "rails-css_unused", path: "..."`
- [ ] `bin/rails css_unused:report` on that app
- [x] Update gemspec author/email/homepage placeholders

#### Publication

- [ ] `gem build` succeeded
- [ ] `gem push` completed
- [ ] Tag `v0.1.0` pushed
- [ ] GitHub release created

---

<!-- Paste completed Release blocks above this line, newest first, after each ship. -->
