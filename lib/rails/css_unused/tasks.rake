# frozen_string_literal: true

namespace :css_unused do
  desc "List CSS classes defined in stylesheets but not referenced in views/components"
  task report: :environment do
    require "rails/css_unused"
    Rails::CssUnused.report
  end

  desc "Same as report (alias)"
  task ghosts: :report
end
