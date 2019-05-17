# frozen_string_literal: true

require 'bunny'
require 'flazm_ruby_helpers/class'
require 'json'

module ConsulKvBackup
  # Send diff output to jq command line
  class Amqp
    include FlazmRubyHelpers::Class

    attr_accessor :consul, :git
    def initialize(amqp_config)
      initialize_variables(amqp_config)
      setup_connection
    end

    def setup_connection
      @conn = Bunny.new(amqp_opts)
      @conn.start
      @ch = @conn.create_channel
      @ex = Bunny::Exchange.new(@ch,
                                :topic,
                                @amqp_exchange,
                                durable: true)
      @queue = @ch.queue(@amqp_queue, durable: true).bind(@ex, routing_key: @amqp_routing_key)
    end

    def consume
      @consumer ||= @queue.subscribe(block: true, &itself.method(:process_message))
      nil
    end

    private

    def process_message(delivery_info, properties, body)
      data = JSON.parse(body)
      data['value'] = @consul.consul_key(data['key_path']) if data['new_value']
      
      @git.process_data(data)
    end

    def amqp_opts
      opts = {}
      opts[:vhost] = @amqp_vhost
      opts[:username] = @amqp_username
      opts[:password] = @amqp_password
      if @amqp_addresses
        opts[:addresses] = @amqp_addresses
      elsif @amqp_hosts
        opts[:hosts] = @amqp_hosts
        opts[:port] = @amqp_port if @rabbitmq_port
      elsif @amqp_host
        opts[:host] = @amqp_host
        opts[:port] = @amqp_port if @rabbitmq_port
      end
      opts
    end

    def defaults
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
      {
        logger: logger,
        amqp_host: 'localhost',
        amqp_hosts: nil,
        amqp_addresses: nil,
        amqp_port: nil,
        amqp_vhost: '/',
        amqp_username: 'guest',
        amqp_password: 'guest',
        amqp_queue: nil,
        amqp_exchange: "amq.topic",
        amqp_routing_key: 'consul_watcher.key.#'
      }
    end
  end
end
