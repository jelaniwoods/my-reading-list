require "rails_helper"

RSpec.describe "Production polling costs" do
  around do |example|
    keys = %w[JOB_CONCURRENCY SOLID_QUEUE_DISPATCH_INTERVAL SOLID_QUEUE_POLL_INTERVAL SOLID_CABLE_POLL_INTERVAL]
    previous = keys.to_h { |key| [key, ENV[key]] }
    keys.each { |key| ENV.delete(key) }
    example.run
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  it "keeps default Queue worker polling above the metered-egress floor" do
    config = Rails.application.config_for(:queue, env: :production)
    interval = config.fetch(:workers).first.fetch(:polling_interval)

    expect(interval).to be >= 1.second
  end

  it "keeps default Queue dispatcher polling above the metered-egress floor" do
    config = Rails.application.config_for(:queue, env: :production)
    interval = config.fetch(:dispatchers).first.fetch(:polling_interval)

    expect(interval).to be >= 1.second
  end

  it "keeps default Cable polling above the metered-egress floor" do
    config = Rails.application.config_for(:cable, env: :production)
    allow(Rails.application).to receive(:config_for).with("cable").and_return(config)

    expect(SolidCable.polling_interval).to be >= 1.second
  end
end
