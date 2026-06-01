# frozen_string_literal: true

require_relative "lib/rails/css_unused/version"

Gem::Specification.new do |spec|
  spec.name          = "rails-css_unused"
  spec.version       = Rails::CssUnused::VERSION
  spec.authors       = ["sghani001"]
  spec.email         = ["sghani001@users.noreply.github.com"]

  spec.summary       = "Find unused CSS classes in Rails apps — fast, accurate static analysis"
  spec.description   = <<~DESC
    rails-css_unused scans your stylesheets (CSS/SCSS/Sass) and all view templates
    (ERB, HAML, Slim), ViewComponents, Phlex components, and Stimulus JS controllers
    to report CSS class selectors that are defined but never referenced. Supports
    BEM naming, dynamic class detection, source-file attribution, CI exit codes,
    and configurable ignore lists — zero runtime overhead.
  DESC
  spec.homepage      = "https://github.com/sghani001/rails-css_unused"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = spec.homepage
  spec.metadata["changelog_uri"]     = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*"].select { |f| File.file?(f) } +
      %w[README.md LICENSE.txt CHANGELOG.md].select { |f| File.file?(f) }
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0", "< 9"

  spec.add_development_dependency "rake",  "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
end
