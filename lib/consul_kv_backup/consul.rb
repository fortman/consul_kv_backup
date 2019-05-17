# frozen_string_literal: true

require 'flazm_ruby_helpers/class'
require 'diplomat'

module ConsulKvBackup
  # Consul storage for previous watch data
  class Consul
    include FlazmRubyHelpers::Class

    def initialize(consul_config)
      initialize_variables(consul_config)
      setup_connection
    end

    def consul_key(key_path)
      Diplomat::Kv.get(key_path)
    end

    private

    def setup_connection
      Diplomat.configure do |config|
        # Set up a custom Consul URL
        config.url = @consul_http_addr
        # Set extra Faraday configuration options and custom access token (ACL)
        config.options = {headers: {"X-Consul-Token" => @consul_token}}
      end
    end

    def defaults
      logger = Logger.new(STDOUT)
      logger.level = Logger::WARN
      {
        logger: logger,
        consul_http_addr: 'http://localhost:8500',
        consul_token: nil,
      }
    end
  end
end
