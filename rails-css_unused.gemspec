# frozen_string_literal: true

require_relative "lib/rails/css_unused/version"

Gem::Specification.new do |spec|
  spec.name          = "rails-css_unused"
  spec.version       = Rails::CssUnused::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]

  spec.summary       = "Find unused CSS classes in Rails apps via static analysis"
  spec.description   = <<~DESC
    A lightweight Rake task that regex-scans views and components for CSS class
    references, compares them to selectors in your stylesheets, and reports
    ghost classes defined in CSS but never used in templates.
  DESC
  spec.homepage      = "https://github.com/your-org/rails-css_unused"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    if File.directory?(".git")
      `git ls-files -z 2>NUL`.split("\x0").reject { |f| f.start_with?("spec/") }
    else
      Dir["lib/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md", "PUBLISHING.md"].select { |f| File.file?(f) }
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
end
