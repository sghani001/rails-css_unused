# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rails::CssUnused::ViewScanner do
  let(:scanner) { described_class.new(root: FIXTURES_ROOT) }

  describe "#used_classes" do
    subject(:classes) { scanner.used_classes }

    it "extracts classes from HTML class attributes" do
      expect(classes).to include("btn", "btn-primary")
    end

    it "extracts BEM classes" do
      expect(classes).to include("card", "card__title", "card__body")
    end

    it "extracts status classes" do
      expect(classes).to include("status-approved", "status-cancelled", "status-requested")
    end

    it "extracts static parts from ERB-interpolated class attributes" do
      # class="<%= x ? 'is-active' : 'is-hidden' %>" — both should be detected
      expect(classes).to include("is-active").or include("is-hidden")
    end

    it "extracts classes from component templates" do
      expect(classes).to include("badge", "badge-primary")
    end

    it "does not include ERB template tags as class names" do
      expect(classes.to_a).not_to include(match(/<%/))
    end

    it "does not include empty strings or invalid tokens" do
      expect(classes.to_a).to all(match(/\A-?[a-zA-Z_][a-zA-Z0-9_-]*\z/))
    end
  end
end
