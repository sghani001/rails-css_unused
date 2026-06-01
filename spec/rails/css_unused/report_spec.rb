# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rails::CssUnused::Report do
  let(:fixture_root) { Pathname(__dir__).join("../../fixtures/sample_app").expand_path }

  it "lists ghost classes defined in CSS but absent from views" do
    ghosts = described_class.new(root: fixture_root).ghost_classes.map(&:class_name)

    expect(ghosts).to contain_exactly("orphan-widget", "legacy-banner")
  end

  it "collects classes from views and components" do
    used = Rails::CssUnused::ViewScanner.new(root: fixture_root).used_classes

    expect(used).to include(
      "hero-card", "is-active", "greeting-label", "badge", "badge--primary"
    )
  end
end
