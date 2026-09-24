require "rails_helper"
require_relative "../support/native_presentation_helpers"
require_relative "../support/ui_fixture_controller"

RSpec.describe "Native presentation", type: :system, native: true do
  include NativePresentationHelpers

  it "omits web navigation and ignores a saved browser theme in native views" do
    visit "/"
    page.execute_script("localStorage.setItem('theme', 'dark')")
    page.refresh

    expect(page).to have_selector('body[data-hotwire-native-app="true"]')
    expect(page).to have_no_selector("header.app-header", visible: :all)
    expect(page).to have_no_selector("[data-theme-selector]", visible: :all)
    mode = (Rails.application.config.x.ui_theme == "toggle") ? "auto" : Rails.application.config.x.ui_theme
    expected_dark = (mode == "auto") ? page.evaluate_script("matchMedia('(prefers-color-scheme: dark)').matches") : mode == "dark"
    expect(page.evaluate_script("document.documentElement.classList.contains('dark')")).to eq(expected_dark)
  end

  it "gives native buttons and form controls comfortable touch targets" do
    visit "/404"

    expect(rendered_size("main .btn").fetch("height")).to be >= 48

    add_native_presentation_controls
    %w[small-button small-input small-select table-link large-button].each do |id|
      expect(rendered_size("##{id}").fetch("height")).to be >= 48
    end
    %w[small-button table-link].each do |id|
      expect(rendered_size("##{id}").fetch("width")).to be >= 48
    end
  end

  it "scales native typography and controls while preserving the configured font" do
    visit "/404"
    font_family = computed_property("html", "fontFamily")
    heading_size = computed_property("main h1", "fontSize").to_f
    root_size = computed_property("html", "fontSize").to_f

    [24, 32].each do |size|
      resolve_native_body_font(size: size)

      expect(computed_property("html", "fontSize")).to eq("#{size}px")
      expect(computed_property("html", "fontFamily")).to eq(font_family)
      expect(computed_property("main h1", "fontSize").to_f).to be_within(0.1).of(heading_size * size / root_size)
      expect(rendered_size("main .btn").fetch("height")).to be >= 48 * size / root_size
    end
  end

  it "retains heading semantics when hiding browser navigation in native views" do
    visit "/privacy"
    add_native_presentation_controls

    expect(page).to have_selector("h2#native-heading:not([aria-hidden=true])", text: "Page heading", visible: :all)
    expect(page).to have_no_selector("#browser-only")
    expect(page).to have_no_selector("#browser-table-link")
  end

  it "keeps error pages within a narrow native viewport at large text sizes" do
    [320, 360].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 780, deviceScaleFactor: 1, mobile: true)

      %w[/404 /422 /500 /__ui/forbidden].each do |path|
        visit path
        resolve_native_body_font(size: 53)

        expect(page.evaluate_script("innerWidth")).to eq(width)
        expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= width
        assert_no_accessibility_violations
      end
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  it "keeps long native button labels readable within narrow controls at large text sizes" do
    visit "/privacy"
    add_narrow_button_group
    resolve_native_body_font(size: 53)
    group_width = rendered_size("#narrow-buttons").fetch("width")

    %w[long-button unbroken-button long-button-link].each do |id|
      bounds = rendered_size("##{id}")
      text = rendered_text_bounds("##{id}")

      expect(bounds.fetch("width")).to be <= group_width
      expect(bounds.fetch("height")).to be >= 159
      expect(text.fetch("width")).to be <= bounds.fetch("width")
      expect(text.fetch("height")).to be <= bounds.fetch("height")
    end
  end
end
