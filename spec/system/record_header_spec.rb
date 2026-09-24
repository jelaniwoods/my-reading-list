require "rails_helper"
require_relative "../support/ui_fixture_controller"

RSpec.describe "Record navigation", type: :system do
  it "keeps record links accessible to pointer and keyboard users in both themes" do
    original_theme = Rails.application.config.x.ui_theme

    %w[light dark].each do |theme|
      Rails.application.config.x.ui_theme = theme
      [1280, 390].each do |width|
        page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 900, deviceScaleFactor: 1, mobile: false)
        visit "/__ui/record_list"
        linked_row = find("#record-list a")
        linked_row.hover
        assert_no_accessibility_violations

        find("#before-record-list").click
        find("#before-record-list").send_keys(:tab)
        expect(page).to have_selector("#record-list a:focus-visible")
        assert_no_accessibility_violations

        page.send_keys :enter
        expect(page).to have_current_path(privacy_path)
      end
    end
  ensure
    Rails.application.config.x.ui_theme = original_theme
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  it "keeps long collection names and navigation usable in narrow viewports" do
    original_theme = Rails.application.config.x.ui_theme
    descriptor = "A person with an intentionally long name — Avery Bellwether-Somerset #{"W" * 80}"
    label = "Back to #{descriptor}"

    %w[light dark].each do |theme|
      Rails.application.config.x.ui_theme = theme
      [1280, 390, 320].each do |width|
        page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 900, deviceScaleFactor: 1, mobile: false)
        visit "/__ui/record_header?#{{title: "Credits for #{descriptor}", label:}.to_query}"

        expect(page).to have_selector("h1", text: "Credits for #{descriptor}")
        expect(page).to have_link(label, href: privacy_path)
        expect(page).to have_link("Add Credit", href: terms_path)
        expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= width
        assert_no_accessibility_violations
      end
    end

    click_link label
    expect(page).to have_current_path(privacy_path)
    page.go_back
    click_link "Add Credit"
    expect(page).to have_current_path(terms_path)
  ensure
    Rails.application.config.x.ui_theme = original_theme
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end
end
