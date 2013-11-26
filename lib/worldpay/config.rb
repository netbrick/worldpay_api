require "yaml"

module WorldPay
  BASE_PATH = File.expand_path("../../../", __FILE__)

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure_from_yaml(path)
    yaml = YAML.load_file(path)
    return unless yaml
    configuration.environment = yaml["environment"]
    configuration.merchant_id = yaml["merchant_id"]
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

  class Configuration
    attr_accessor :environment, :merchant_id

    def initialize
      # Load config.yml
      config = YAML.load_file(File.join(BASE_PATH, "config", "config.yml"))
      @urls  = config["url"]
    end

    def url
      env = @environment.nil? ? "test" : @environment.to_s

      (%w("test" "production).include? env) ? @urls[env] : @urls["test"]
    end
  end
end
