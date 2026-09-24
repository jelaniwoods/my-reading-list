module WebMockNetworkPolicy
  SELENIUM_PORT = 4444

  def self.apply!(environment = ENV)
    options = {allow_localhost: true}
    allowed_endpoints = []
    selenium_host = environment["SELENIUM_HOST"].to_s.strip
    app_host = environment["CAPYBARA_SERVER_HOST"].to_s.strip
    app_port = environment["CAPYBARA_SERVER_PORT"].to_s.strip

    allowed_endpoints << [selenium_host, SELENIUM_PORT] unless selenium_host.empty?
    allowed_endpoints << [app_host, Integer(app_port, 10)] unless app_host.empty? || app_port.empty?

    unless allowed_endpoints.empty?
      options[:allow] = lambda do |uri|
        uri.scheme == "http" && allowed_endpoints.include?([uri.host, uri.port])
      end
    end

    WebMock.disable_net_connect!(**options)
  end
end
