# frozen_string_literal: true

namespace :css_unused do
  desc "List CSS classes defined in stylesheets but never referenced in views/components"
  task report: :environment do
    require "rails/css_unused"
    exit_code = Rails::CssUnused.report
    exit(exit_code) if exit_code != 0
  end

  desc "Alias for css_unused:report"
  task ghosts: :report

  desc "Exit with code 1 if any ghost classes exist (CI-friendly)"
  task ci: :environment do
    require "rails/css_unused"
    original = Rails::CssUnused.configuration.fail_on_unused
    Rails::CssUnused.configuration.fail_on_unused = true
    exit_code = Rails::CssUnused.report
    Rails::CssUnused.configuration.fail_on_unused = original
    exit(exit_code) if exit_code != 0
  end

  desc "Show ghost classes with their source stylesheet file"
  task report_verbose: :environment do
    require "rails/css_unused"
    original = Rails::CssUnused.configuration.show_source_files
    Rails::CssUnused.configuration.show_source_files = true
    Rails::CssUnused.report
    Rails::CssUnused.configuration.show_source_files = original
  end
end
