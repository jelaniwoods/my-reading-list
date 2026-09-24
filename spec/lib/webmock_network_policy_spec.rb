require "rails_helper"
require_relative "../support/webmock_network_policy"

RSpec.describe WebMockNetworkPolicy do
  after do
    described_class.apply!
  end

  it "allows only localhost and the configured container endpoints" do
    described_class.apply!(
      "CAPYBARA_SERVER_HOST" => "rails-app",
      "CAPYBARA_SERVER_PORT" => "45678",
      "SELENIUM_HOST" => "selenium"
    )

    expect(WebMock.net_connect_allowed?("http://localhost:3000")).to be_truthy
    expect(WebMock.net_connect_allowed?("http://selenium:4444/status")).to be_truthy
    expect(WebMock.net_connect_allowed?("http://rails-app:45678/__identify__")).to be_truthy
    expect(WebMock.net_connect_allowed?("http://selenium:4445/status")).to be_falsey
    expect(WebMock.net_connect_allowed?("http://rails-app:45679/__identify__")).to be_falsey
    expect(WebMock.net_connect_allowed?("https://rails-app:45678/__identify__")).to be_falsey
    expect(WebMock.net_connect_allowed?("https://example.com")).to be_falsey
  end

  it "does not widen network access without configured remote endpoints" do
    described_class.apply!({})

    expect(WebMock.net_connect_allowed?("http://127.0.0.1:3000")).to be_truthy
    expect(WebMock.net_connect_allowed?("http://selenium:4444/status")).to be_falsey
    expect(WebMock.net_connect_allowed?("https://example.com")).to be_falsey
  end
end
