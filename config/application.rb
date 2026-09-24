require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ReadingList
  class ContentSecurityPolicyNonce
    def initialize(app)
      @app = app
    end

    def call(env)
      # ShowExceptions duplicates the environment; seed once so its layout and response header agree.
      ActionDispatch::Request.new(env).content_security_policy_nonce
      @app.call(env)
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks templates])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Exceptions render through the router: branded 404/422/500 in the app layout.
    config.middleware.insert_before ActionDispatch::ShowExceptions, ContentSecurityPolicyNonce
    config.exceptions_app = routes

    # RSpec and FactoryBot own ordinary model and scaffold continuation.
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec, view_specs: false, helper_specs: false, routing_specs: false
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.helper false
      g.assets false
    end

    # Variant processing starts disabled. When the application needs image variants,
    # choose a processor and add its dependencies.
    config.active_storage.variant_processor = :disabled
  end
end
