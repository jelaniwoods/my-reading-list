module SystemSpecSupport
  AXE_NAVIGATION_RACE_ERROR = /Cannot read properties of undefined \(reading ['"](?:runPartial|utils)['"]\)/
  TURBO_BUSY_SELECTOR = [
    "html[aria-busy]",
    "form[aria-busy]",
    "turbo-frame[aria-busy]",
    "html[data-turbo-not-loaded]",
    "html[data-turbo-loading]",
    "html[data-turbo-preview]"
  ].join(", ").freeze

  def wait_for_turbo
    return if Capybara.current_driver == :rack_test

    Selenium::WebDriver::Wait.new(
      timeout: Capybara.default_max_wait_time * 3,
      interval: Capybara.default_retry_interval,
      ignore: [
        Selenium::WebDriver::Error::JavascriptError,
        Selenium::WebDriver::Error::StaleElementReferenceError
      ]
    ).until do
      page.driver.browser.execute_script(<<~JS, TURBO_BUSY_SELECTOR)
        return document.readyState === "complete" && !document.querySelector(arguments[0])
      JS
    end
  end

  # Axe can be injected into the document Turbo is replacing. Retry only that
  # known injection race; accessibility failures and unrelated errors still fail.
  def assert_no_accessibility_violations(...)
    wait_for_turbo
    super
  rescue => error
    raise unless error.message.match?(AXE_NAVIGATION_RACE_ERROR)

    wait_for_turbo
    super
  end
end

# A form redirect briefly clears aria-busy before Turbo marks the next visit.
# The application submit/load markers keep that gap covered for every click.
module WaitForTurboBeforeClick
  def click(...)
    unless session.driver.is_a?(Capybara::RackTest::Driver)
      assert_no_ancestor SystemSpecSupport::TURBO_BUSY_SELECTOR, visible: :all
    end

    super
  end
end

Capybara::Node::Element.prepend(WaitForTurboBeforeClick)
Capybara.disable_animation = true
Capybara.save_path = Rails.root.join("tmp/screenshots")

RSpec.configure do |config|
  config.include SystemSpecSupport, type: :system

  config.before(type: :system) do |example|
    server_host = ENV["CAPYBARA_SERVER_HOST"]
    server_port = ENV["CAPYBARA_SERVER_PORT"]
    raise "CAPYBARA_SERVER_HOST and CAPYBARA_SERVER_PORT must be set together" if server_host.nil? != server_port.nil?

    options = {}
    if server_host
      served_by host: server_host, port: server_port
      options[:browser] = :remote
      options[:url] = "http://#{ENV.fetch("SELENIUM_HOST")}:4444"
    end

    options[:name] = :selenium_hotwire_native if example.metadata[:native]
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: options do |browser_options|
      if example.metadata[:native]
        browser_options.add_argument("--user-agent=Foundation/1.0; Hotwire Native iOS; Turbo Native iOS; bridge-components: []")
      end
    end
  end
end
