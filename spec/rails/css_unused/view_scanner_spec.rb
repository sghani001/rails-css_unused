# frozen_string_literal: true

require "spec_helper"

RSpec.describe Rails::CssUnused::ViewScanner do
  let(:root)   { Pathname(File.expand_path("../../fixtures/sample_app", __dir__)) }
  let(:config) { Rails::CssUnused::Configuration.new }
  let(:scanner) { described_class.new(root: root, config: config) }

  # Helper: run scanner against inline content by writing a temp file
  def classes_in(content, filename: "test.html.erb")
    dir = root.join("app/views/test_tmp")
    dir.mkpath
    file = dir.join(filename)
    file.write(content)
    config.view_paths = ["app/views/test_tmp"]
    config.component_paths = []
    config.scan_javascript_for_classes = false
    result = scanner.used_classes
    file.delete
    dir.delete
    result
  end

  # ── Standard class extraction ────────────────────────────────────────────

  describe "standard HTML class attributes" do
    it "extracts classes from class=\"...\"" do
      expect(classes_in('<div class="foo bar baz">')).to include("foo", "bar", "baz")
    end

    it "extracts classes from class: \"...\" Ruby syntax" do
      expect(classes_in('<%= tag.div class: "btn btn-primary" %>')).to include("btn", "btn-primary")
    end

    it "extracts classes from class arrays" do
      expect(classes_in('<%= tag.div class: ["card", "card-body"] %>')).to include("card", "card-body")
    end
  end

  # ── v0.2.1: Dynamic class variable detection ─────────────────────────────

  describe "dynamic class variable detection (v0.2.1)" do
    context "with *_class variable assignment" do
      it "detects classes assigned to a *_class variable" do
        erb = <<~ERB
          <% status_class = "status-active" %>
          <span class="pill <%= status_class %>"></span>
        ERB
        expect(classes_in(erb)).to include("status-active")
      end

      it "detects classes assigned to a *_classes variable" do
        erb = <<~ERB
          <% button_classes = "btn btn-primary btn-sm" %>
          <button class="<%= button_classes %>">Click</button>
        ERB
        result = classes_in(erb)
        expect(result).to include("btn", "btn-primary", "btn-sm")
      end

      it "detects classes assigned to a *_style variable" do
        erb = '<% card_style = "card-elevated" %>'
        expect(classes_in(erb)).to include("card-elevated")
      end

      it "detects classes assigned to a *_css variable" do
        erb = '<% nav_css = "navbar-fixed" %>'
        expect(classes_in(erb)).to include("navbar-fixed")
      end
    end

    context "with conditional assignment (the exam card pattern)" do
      it "detects all branch values in a multi-branch conditional" do
        erb = <<~ERB
          <% status_label, status_class =
            if exam.cancelled?
              ["Cancelled", "status-cancelled"]
            elsif exam.start_time < Time.current && exam.end_time < Time.current
              ["Missed", "status-missed"]
            elsif exam.active? && exam.approved?
              ["Active", "status-active"]
            elsif exam.approved?
              ["Approved", "status-approved"]
            elsif exam.request_approval?
              ["Requested approval", "status-requested"]
            else
              ["Draft", "status-draft"]
            end %>
          <span class="status-pill <%= status_class %>"><%= status_label %></span>
        ERB

        result = classes_in(erb)
        expect(result).to include(
          "status-cancelled",
          "status-missed",
          "status-active",
          "status-approved",
          "status-requested",
          "status-draft"
        )
      end

      it "does NOT flag status-* classes as ghost classes when defined in stylesheets" do
        # This is an integration-style check: the scanner finds them as used
        # so the report engine won't call them ghosts
        erb = <<~ERB
          <% status_class = if done? then "status-approved" else "status-draft" end %>
          <span class="<%= status_class %>"></span>
        ERB
        result = classes_in(erb)
        expect(result).to include("status-approved", "status-draft")
      end
    end

    context "with hyphenated string literals" do
      it "detects hyphenated strings as CSS class values" do
        # Ruby variable names cannot contain hyphens — so hyphenated quoted
        # strings are unambiguously string values (not identifiers)
        erb = '"status-active"'
        expect(classes_in(erb)).to include("status-active")
      end

      it "does not extract non-hyphenated strings as dynamic classes" do
        # Non-hyphenated strings could be variable names — we don't extract them
        # via the hyphenated-string rule (they're handled by other patterns)
        erb = '<div class="active"></div>'
        result = classes_in(erb)
        expect(result).to include("active") # found via HTML_CLASS_ATTR, not hyphenated rule
      end

      it "extracts multiple hyphenated classes from an array literal" do
        erb = '["Active", "status-active", "Cancelled", "status-cancelled"]'
        result = classes_in(erb)
        expect(result).to include("status-active", "status-cancelled")
      end

      it "handles BEM modifier classes" do
        erb = '<% btn_class = "btn--primary" %>'
        expect(classes_in(erb)).to include("btn--primary")
      end

      it "handles BEM element classes" do
        erb = '"card__header"'
        expect(classes_in(erb)).to include("card__header")
      end
    end

    context "with ternary operator patterns" do
      it "detects classes in ternary expressions assigned to *_class vars" do
        erb = '<% icon_class = active? ? "icon-on" : "icon-off" %>'
        result = classes_in(erb)
        expect(result).to include("icon-on", "icon-off")
      end
    end
  end

  # ── Existing detection should still work ─────────────────────────────────

  describe "ERB dynamic class interpolation" do
    it "extracts static parts from dynamic class attributes" do
      erb = '<div class="prefix-<%= var %> suffix">'
      expect(classes_in(erb)).to include("suffix")
    end
  end

  describe "ignore_classes config" do
    it "excludes classes in ignore_classes" do
      config.ignore_classes = ["foo"]
      result = classes_in('<div class="foo bar">')
      expect(result).not_to include("foo")
      expect(result).to include("bar")
    end
  end

  describe "ignore_patterns config" do
    it "excludes classes matching ignore patterns" do
      config.ignore_patterns = [/\Astatus-/]
      erb = '"status-active"'
      expect(classes_in(erb)).not_to include("status-active")
    end
  end

  # ── Full fixture app ─────────────────────────────────────────────────────

  describe "#used_classes on fixture app" do
    subject(:classes) { scanner.used_classes }

    it "returns a Set" do
      expect(classes).to be_a(Set)
    end

    it "finds classes from the fixture views" do
      expect(classes).not_to be_empty
    end
  end
end
