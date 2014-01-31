# -*- mode:ruby; coding:utf-8; -*-
require 'worldpay/config'

# Add payment
require 'worldpay/models/payment'

# Automatically load configuration from config/worldpay.yml
require 'worldpay/railtie' if defined?(::Rails) && ::Rails::VERSION::MAJOR >= 3

# Other methods
module WorldPay
  # Validate params
  def self.validate_mac_params?(params)
    # False when mac is missing!
    fail "Error with payment validation" if params[:mac].blank?

    # Prepare
    key = ""

    # All attributes
    [ :orderKey, :paymentAmount, :paymentCurrency, :paymentStatus ].each do |value|
      key << params[value].to_s
    end

    # Add Mac
    key << WorldPay.configuration.mac

    # MD5 validation
    fail "Erorr with payment validation" if Digest::MD5.hexdigest(key) != params[:mac]

    # Return payment status
    params[:paymentStatus].underscore.to_sym
  end

  # Get order number from order key
  def self.parse_order_key(order_key)
    match_data = /.*\^#{WorldPay.configuration.merchant_id}\^(\d+)$/.match order_key

    # Return expression
    match_data ? match_data[1] : nil
  end
end
