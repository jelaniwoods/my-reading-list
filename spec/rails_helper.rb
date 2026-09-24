require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "webmock/rspec"
require "n_plus_one_control/rspec"

Rails.root.glob("spec/support/**/*.rb").sort.each { |file| require file }

ActiveRecord::Migration.maintain_test_schema!
WebMockNetworkPolicy.apply!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.file_fixture_path = Rails.root.join("spec/fixtures/files")
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods

  config.around do |example|
    Bullet.profile { example.run }
  end
end
