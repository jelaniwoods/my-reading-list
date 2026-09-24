require "rails_helper"

RSpec.describe "Security headers", type: :request do
  it "enforces the Content-Security-Policy with a nonce" do
    get "/up"

    csp = response.headers.fetch("Content-Security-Policy")
    expect(response.headers["Content-Security-Policy-Report-Only"]).to be_nil
    expect(csp).to include("default-src 'self'", "frame-ancestors 'none'")
    expect(csp).to match(/nonce-[A-Za-z0-9+\/=]{16,}/)
  end

  it "denies unused browser capabilities" do
    get "/up"

    expect(response.headers.fetch("Permissions-Policy")).to include("camera=()", "geolocation=()", "microphone=()")
  end
end
