require "rails_helper"

RSpec.describe "UI theme", type: :system do
  it "preserves the configured appearance through a browser visit" do
    visit "/privacy"
    page.execute_script("localStorage.setItem('theme', 'dark')")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [{name: "prefers-color-scheme", value: "dark"}])
    page.refresh
    mode = Rails.application.config.x.ui_theme
    expected = (mode == "light") ? "light" : "dark"
    expect(page).to have_selector("html[data-theme=#{expected}]", visible: :all)
    expect(page.evaluate_script("getComputedStyle(document.documentElement).colorScheme")).to eq(expected)
    if mode == "toggle"
      expect(page).to have_select(I18n.t("nav.theme"), selected: I18n.t("nav.theme_dark"))
    else
      expect(page).to have_no_selector("[data-theme-selector]", visible: :all)
    end
    click_link I18n.t("app_name")
    expect(page).to have_selector("html[data-theme=#{expected}]", visible: :all)
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", features: [{name: "prefers-color-scheme", value: "light"}])
  end
end
