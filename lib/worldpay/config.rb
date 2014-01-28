# -*- mode:ruby; coding:utf-8; -*-
require 'yaml'

# WorldPay default module
module WorldPay
  BASE_PATH = File.expand_path('../../../', __FILE__)

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure_from_yaml(path)
    yaml = YAML.load_file(path)[Rails.env]
    return unless yaml
    configuration.environment = yaml['environment']
    configuration.merchant_id = yaml['merchant_id']
    configuration.password    = yaml['password']
    configuration.mac         = yaml['mac']
  end

  def self.configure_from_rails
    path = ::Rails.root.join('config', 'worldpay.yml')
    configure_from_yaml(path) if File.exist?(path)
    env = if defined?(::Rails) && ::Rails.respond_to?(:env)
            ::Rails.env.to_sym
          elsif defined?(::RAILS_ENV)
            ::RAILS_ENV.to_sym
          end

    configuration.environment ||= (env == :development) ? :test : env
    configuration
  end

  # WorldPay configuration settings
  class Configuration
    attr_accessor :environment, :mac, :merchant_id, :payment_service_version, :shipping_addresses, :password, :valid_address_patterns

    def initialize
      # Load config.yml
      config = YAML.load_file(File.join(BASE_PATH, 'config', 'config.yml'))['worldpay_config']
      @urls                    = config['url']
      @payment_service_version = config['payment_service_version']
      @shipping_addresses      = config['shipping_adress_fields']
      @valid_address_patterns  = config['valid_address_patterns']
      @mac                     = config['mac']
    end

    def url
      env = (@environment.nil?) ? 'test' : @environment.to_s

      (%w(test production).include? env) ? @urls[env] : @urls['test']
    end
  end
end
