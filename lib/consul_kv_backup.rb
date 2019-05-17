# frozen_string_literal: true

require 'consul_kv_backup/consul'
require 'consul_kv_backup/amqp'
require 'consul_kv_backup/git'

module ConsulKvBackup
  def self.start(config)
    assemble(config)
    @amqp.consul = @consul
    @amqp.git = @git
    @amqp.consume
  end

  def self.assemble(config)
    @consul = ConsulKvBackup::Consul.new(config['consul'])
    @amqp = ConsulKvBackup::Amqp.new(config['amqp'])
    @git = ConsulKvBackup::Git.new(config['git'])
  end
end
