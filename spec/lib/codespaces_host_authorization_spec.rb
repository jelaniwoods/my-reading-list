require "json"
require "open3"
require "rails_helper"

RSpec.describe "Codespaces host authorization" do
  let(:codespace_name) { "test-codespace-abc123" }
  let(:forwarding_domain) { "forwarding.example" }
  let(:default_forwarded_host) { "#{codespace_name}-3000.#{forwarding_domain}" }

  it "admits only the exact current forwarded host and still requires a valid CSRF token" do
    exact_host = default_forwarded_host
    sibling_host = "another-codespace-3000.#{forwarding_domain}"
    result = development_request_statuses(exact_host, sibling_host, ".#{forwarding_domain}")

    expect(result.dig("statuses", exact_host)).to eq(200)
    expect(result.dig("statuses", sibling_host)).to eq(403)
    expect(result.dig("statuses", ".#{forwarding_domain}")).to eq(403)
    expect(result.dig("csrf", "valid_token_status")).to eq(204)
    expect(result.dig("csrf", "invalid_token_status")).to eq(422)
    expect(result.dig("csrf", "missing_token_status")).to eq(422)
  end

  it "uses the configured Rails port in the forwarded host" do
    exact_host = "#{codespace_name}-4567.#{forwarding_domain}"
    result = development_request_statuses(exact_host, default_forwarded_host, port: 4567)

    expect(result.dig("statuses", exact_host)).to eq(200)
    expect(result.dig("statuses", default_forwarded_host)).to eq(403)
  end

  [nil, "false"].each do |codespaces|
    it "blocks forwarded hosts and cross-origin posts when CODESPACES is #{codespaces.inspect}" do
      result = development_request_statuses(default_forwarded_host, codespaces: codespaces)

      expect(result.dig("statuses", default_forwarded_host)).to eq(403)
      expect(result.dig("csrf", "valid_token_status")).to eq(422)
    end
  end

  it "uses port 3000 when PORT is unset" do
    result = development_request_statuses(default_forwarded_host, port: nil)

    expect(result.dig("statuses", default_forwarded_host)).to eq(200)
  end

  def development_request_statuses(*hosts, codespaces: "true", port: 3000)
    # Real controller requests traverse development's pending-migration guard,
    # so the child intentionally inherits the caller's prepared database.
    environment = {
      "RAILS_ENV" => "development",
      "RAILS_DEVELOPMENT_HOSTS" => nil,
      "CODESPACES" => codespaces,
      "CODESPACE_NAME" => codespace_name,
      "GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" => forwarding_domain,
      "PORT" => port&.to_s,
      "SKYLIGHT_ENABLED" => "false"
    }
    script = <<~RUBY
      require "json"
      request = Rack::MockRequest.new(Rails.application)
      hosts = #{hosts.inspect}
      statuses = hosts.to_h do |host|
        [host, request.get("/robots.txt", "HTTP_HOST" => host).status]
      end

      Object.const_set(
        :CodespacesCsrfProbeController,
        Class.new(ApplicationController) do
          define_method(:token) { render plain: form_authenticity_token }
          define_method(:create) { head :no_content }
        end
      )
      Rails.application.routes.append do
        get "/__codespaces_csrf_probe", to: "codespaces_csrf_probe#token"
        post "/__codespaces_csrf_probe", to: "codespaces_csrf_probe#create"
      end
      Rails.application.reload_routes!

      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.host! ENV["CODESPACES"] == "true" ? hosts.first : "localhost"
      session.https!
      session.get "/__codespaces_csrf_probe"
      token = session.response.body

      origin = "http://localhost:\#{ENV.fetch("PORT", 3000)}"
      session.post(
        "/__codespaces_csrf_probe",
        params: {authenticity_token: token},
        headers: {"Origin" => origin}
      )
      valid_token_status = session.response.status
      session.post(
        "/__codespaces_csrf_probe",
        params: {authenticity_token: "invalid"},
        headers: {"Origin" => origin}
      )
      invalid_token_status = session.response.status
      session.post "/__codespaces_csrf_probe", headers: {"Origin" => origin}
      csrf = {
        valid_token_status: valid_token_status,
        invalid_token_status: invalid_token_status,
        missing_token_status: session.response.status
      }

      puts JSON.generate(statuses: statuses, csrf: csrf)
    RUBY
    stdout, stderr, status = Open3.capture3(
      environment,
      Rails.root.join("bin/rails").to_s,
      "runner",
      script,
      chdir: Rails.root.to_s
    )

    expect(status).to be_success, stderr
    expect(stdout).to be_present, stderr
    JSON.parse(stdout.lines.last)
  end
end
