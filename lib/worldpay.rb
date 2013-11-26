# -*- mode:ruby; coding:utf-8; -*-
require 'worldpay/config'

# Add payment
require 'worldpay/models/payment'

# Automatically load configuration from config/worldpay.yml
require 'worldpay/railtie' if defined?(::Rails) && ::Rails::VERSION::MAJOR >= 3
