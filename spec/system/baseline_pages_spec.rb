require "rails_helper"
require_relative "../support/native_presentation_helpers"
require_relative "../support/ui_fixture_controller"

RSpec.describe "Baseline pages", type: :system do
  include NativePresentationHelpers

  let(:baseline_pages) { ["/", "/privacy", "/terms", "/404", "/422", "/500", "/__ui/forbidden"] }

  %w[light dark].each do |theme|
    it "keeps baseline pages accessible in #{theme} mode" do
      original_theme = Rails.application.config.x.ui_theme
      Rails.application.config.x.ui_theme = theme

      baseline_pages.each do |path|
        visit path
        expect(page).to have_selector("html[data-theme=#{theme}]", visible: :all)
      end
    ensure
      Rails.application.config.x.ui_theme = original_theme
    end
  end

  it "returns home from the access denied page" do
    visit "/__ui/forbidden"

    within "main" do
      click_link I18n.t("errors.back_home")
    end

    expect(page).to have_current_path(root_path)
  end

  it "provides persistent live regions before messages arrive" do
    visit "/"

    expect(page).to have_selector("#flash_notices[role='status']", visible: :all)
    expect(page).to have_selector("#flash_alerts[role='alert']", visible: :all)
  end

  it "lets keyboard users skip navigation and focus the main content" do
    visit "/privacy"

    page.send_keys :tab
    expect(page).to have_selector("a:focus", text: I18n.t("nav.skip_to_content"))
    page.send_keys :enter

    expect(page).to have_selector("main:focus")
  end

  it "keeps browser presentation independent of native text-size preferences" do
    visit "/404"
    add_native_presentation_controls
    font_size = computed_property("html", "fontSize")
    font_family = computed_property("html", "fontFamily")
    line_height = computed_property("html", "lineHeight")
    heading_size = computed_property("main h1", "fontSize")
    button_size = rendered_size("main .btn")

    resolve_native_body_font(size: 24)

    expect(computed_property("html", "fontSize")).to eq(font_size)
    expect(computed_property("html", "fontFamily")).to eq(font_family)
    expect(computed_property("html", "lineHeight")).to eq(line_height)
    expect(computed_property("main h1", "fontSize")).to eq(heading_size)
    expect(rendered_size("main .btn")).to eq(button_size)
    expect(page).to have_selector("#native-heading", text: "Page heading")
    expect(page).to have_selector("#browser-only", text: "Browser navigation")
    expect(page).to have_link("Details", id: "browser-table-link")
  end
end
