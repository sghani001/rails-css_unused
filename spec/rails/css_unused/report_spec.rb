# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rails::CssUnused::Report do
  let(:output) { StringIO.new }
  let(:report) { described_class.new(root: FIXTURES_ROOT, output: output) }

  describe "#ghost_classes" do
    subject(:ghosts) { report.ghost_classes }

    it "returns ghost classes that are in CSS but not in views" do
      names = ghosts.map(&:class_name)
      expect(names).to include("ghost-one", "ghost-two", "old-unused-class")
    end

    it "does NOT flag classes that are used in views" do
      names = ghosts.map(&:class_name)
      expect(names).not_to include("btn", "card", "status-approved")
    end

    it "does NOT include file-extension noise as ghost classes" do
      names = ghosts.map(&:class_name)
      expect(names).not_to include("png", "css", "jpg")
    end

    it "returns Ghost structs with class_name attribute" do
      expect(ghosts).to all(respond_to(:class_name))
    end
  end

  describe "#print_summary" do
    it "prints the report without raising" do
      expect { report.print_summary }.not_to raise_error
    end

    it "includes the count headers" do
      report.print_summary
      text = output.string
      expect(text).to include("Stylesheet classes found")
      expect(text).to include("View classes referenced")
      expect(text).to include("Ghost classes")
    end

    it "lists ghost class names" do
      report.print_summary
      expect(output.string).to include("ghost-one")
    end

    it "returns 0 when fail_on_unused is false" do
      code = report.print_summary
      expect(code).to eq(0)
    end

    it "returns 1 when fail_on_unused is true and there are ghost classes" do
      Rails::CssUnused.configure { |c| c.fail_on_unused = true }
      r    = described_class.new(root: FIXTURES_ROOT, output: StringIO.new)
      code = r.print_summary
      # We have ghost classes in fixtures, so code should be 1
      expect(code).to eq(1)
    end
  end
end
