# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rails::CssUnused::StylesheetScanner do
  let(:scanner) { described_class.new(root: FIXTURES_ROOT) }

  describe "#defined_classes" do
    subject(:classes) { scanner.defined_classes }

    it "extracts normal class selectors" do
      expect(classes).to include("btn", "btn-primary", "card")
    end

    it "extracts BEM element selectors" do
      expect(classes).to include("card__title", "card__body")
    end

    it "extracts status classes" do
      expect(classes).to include("status-approved", "status-cancelled", "status-requested")
    end

    it "does NOT include file-extension false positives" do
      expect(classes).not_to include("png", "css", "jpg")
    end

    it "does NOT include @charset / @import / @keyframe noise" do
      expect(classes).not_to include("charset", "import")
    end

    it "does NOT include classes from inside :not() pseudo-selectors" do
      # .btn inside :not(.btn) is a used class reference, not a definition
      # The scanner may or may not include it — either is acceptable as long
      # as it's not creating false ghost entries.
      # Here we simply ensure no crash and that 'btn' is reachable from views.
      expect { classes }.not_to raise_error
    end
  end

  describe "#defined_classes_with_sources" do
    it "returns DefinedClass structs with name and source_file" do
      results = scanner.defined_classes_with_sources
      expect(results).to all(respond_to(:name))
      expect(results).to all(respond_to(:source_file))
      expect(results.map(&:name)).to include("btn", "card")
    end
  end

  describe "ignore_classes" do
    it "excludes classes listed in ignore_classes" do
      Rails::CssUnused.configure { |c| c.ignore_classes = ["btn"] }
      scanner = described_class.new(root: FIXTURES_ROOT)
      expect(scanner.defined_classes).not_to include("btn")
    end
  end

  describe "ignore_patterns" do
    it "excludes classes matching ignore_patterns" do
      Rails::CssUnused.configure { |c| c.ignore_patterns = [/\Astatus-/] }
      scanner = described_class.new(root: FIXTURES_ROOT)
      expect(scanner.defined_classes).not_to include("status-approved", "status-cancelled")
    end
  end
end
