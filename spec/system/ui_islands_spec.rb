require "rails_helper"
require_relative "../support/ui_fixture_controller"

RSpec.describe "Interactive controls", type: :system do
  it "keeps responsive navigation accessible and cleans its sheet before Turbo visits" do
    page.current_window.resize_to(390, 844)
    visit "/__ui/fixture"
    click_button I18n.t("nav.menu")
    expect(page).to have_selector("[role=dialog]", text: "Fixture home")
    assert_no_accessibility_violations
    page.send_keys :escape
    expect(page).to have_no_selector("[role=dialog]")
    expect(page).to have_selector("button:focus", text: I18n.t("nav.menu"))
    click_button I18n.t("nav.menu")
    within("[role=dialog]") { click_link "Privacy" }
    expect(page).to have_selector("h1", text: I18n.t("pages.privacy.heading"))
    expect(page).to have_no_selector("[data-slot=sheet-content]", visible: :all)
    page.go_back
    expect(page).to have_selector("button", text: I18n.t("nav.menu"))
    page.current_window.resize_to(1280, 900)
    expect(page).to have_no_selector("button", text: I18n.t("nav.menu"))
    expect(page).to have_selector(".app-navigation-desktop", text: "Fixture home")
  end

  it "delivers a quiet success toast once and keeps guidance in page flow" do
    visit "/__ui/success"
    expect(page).to have_selector("[data-sonner-toast]", text: "Saved the record")
    expect(page).to have_no_selector("[data-transient-message]", visible: :all)
    assert_no_accessibility_violations
    click_link "Leave fixture"
    page.go_back
    expect(page).to have_selector("h1", text: "UI fixture")
    expect(page).to have_no_selector("[data-sonner-toast]")
    visit "/__ui/guidance"
    expect(page).to have_selector("#flash_notices", text: "Check your email to continue")
    expect(page).to have_selector("#flash_alerts", text: "The request needs attention")
    expect(page).to have_selector("#flash_notices", text: "Keep this recovery code")
    expect(page).to have_no_selector("[data-sonner-toast]")
  end

  it "retains navigation and success feedback without JavaScript" do
    page.current_window.resize_to(390, 844)
    visit "/__ui/fixture"
    browser = page.driver.browser
    browser.execute_cdp("Network.enable")
    browser.execute_cdp("Network.setBlockedURLs", urls: ["*application*.js*"])
    browser.navigate.to(page.current_url.sub("/__ui/fixture", "/__ui/success"))
    expect(page).to have_selector("main > [data-controller=turbo-mount-flash-toasts] [data-island-fallback]", text: "Saved the record")
    expect(page).to have_no_selector(".app-navigation [data-island-fallback] a", text: "Fixture home")
    browser.find_element(:css, ".app-navigation summary").click
    expect(page).to have_selector(".app-navigation [data-island-fallback]", text: "Fixture home")
    expect(page).to have_no_selector("[data-island-enhanced=true]", visible: :all)
  ensure
    browser&.execute_cdp("Network.setBlockedURLs", urls: [])
  end

  it "keeps exactly one pair of persistent live regions with inline guidance" do
    visit "/__ui/guidance?inline=true"
    expect(page).to have_selector("section #flash_notices", text: "Check your email to continue", count: 1)
    expect(page).to have_selector("section #flash_alerts", text: "The request needs attention", count: 1)
    expect(page).to have_selector("#flash_notices", count: 1)
    expect(page).to have_selector("#flash_alerts", count: 1)
    visit "/__ui/fixture?inline=true"
    expect(page).to have_selector("#flash_notices", count: 1)
    expect(page).to have_selector("#flash_alerts", count: 1)
  end
end
