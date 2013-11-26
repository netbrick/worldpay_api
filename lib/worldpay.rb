require "gopay/config"

# Automatically load configuration from config/worldpay.yml
require "worldpay/railtie" if defined?(::Rails) && ::Rails::VERSION::MAJOR >= 3
