# -*- mode:ruby; coding:utf-8; -*-
require 'httpclient'
require 'nokogiri'

module WorldPay
  # Representation of WorldPay payment
  class Payment
    # Attributes
    attr_reader :version, :merchant_id, :order_code, :description, :ammount_value, :ammount_currency_code, :ammount_exponent, :order_content

    # Payments ARRAYS!
    attr_reader :payment_method_mask_include, :payment_method_mask_exclude

    # Shopper informations
    attr_reader :shopper_email_address

    # Redirect URL to proceed payment!
    attr_reader :redirect_url

    # Client
    attr_reader :client, :create_payment_response

    # Shipping addresses!
    WorldPay.configuration.shipping_addresses.each do |attr|
      class_eval <<-EOV
        attr_reader :#{attr}
      EOV
    end

    # Intitalize
    def initialize(attributes = {})
      # WL attributes!
      attributes.each do |key, value|
        instance_variable_set(:"@#{key}", value) if self.respond_to?(key)
      end

      # Default value!
      @payment_method_mask_include ||= %w(ALL)
      @payment_method_mask_exclude ||= []

      # Version & Merchant ID
      @version     ||= WorldPay.configuration.payment_service_version
      @merchant_id ||= WorldPay.configuration.merchant_id
    end

    # All payments!
    def all_payments
      @payment_method_mask_include = %w(ALL)
      @payment_method_mask_exclude = []
    end

    # Only online payments
    def online_payments
      @payment_method_mask_include = %w(ONLINE)
      @payment_method_mask_exclude = []
    end

    # Get XML payment request!
    def get_payment_request
      # Validate payment attributes
      validate_payment_attributes

      # Init builder
      xml = ::Builder::XmlMarkup.new(indent: 0)

      # XML
      xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'

      # Doctype!
      xml.declare! :DOCTYPE, :paymentService, :PUBLIC, '-//WorldPay/DTD WorldPay PaymentService v1//EN', 'http://dtd.worldpay.com/paymentService_v1.dtd'

      # Payment service - version & merchant_id
      xml.tag!('paymentService', version: @version, merchantCode: @merchant_id) do

        # Submit
        xml.tag!('submit') do

          # Order
          xml.tag!('order', orderCode: @order_code) {
            # Description
            xml.description(@description)

            # Ammount
            xml.tag!('amount', value: @ammount_value, currencyCode: @ammount_currency_code, exponent: @ammount_exponent)

            # Order Content - CDATA!
            xml.tag!('orderContent') do
              xml.cdata!(@order_content)
            end

            # Payment method mask
            xml.tag!('paymentMethodMask') {
              # Payment types for include!
              @payment_method_mask_include.each do |method|
                xml.tag!('include', code: method)
              end

              # Payment types for exclude
              @payment_method_mask_exclude.each do |method|
                xml.tag!('exclude', code: method)
              end
            }

            # Shoper payment
            xml.tag!('shopper') {
              xml.shopperEmailAddress(@shopper_email_address)
            }

            # Shipping address?
            if has_shipping_address?
              xml.tag!('shippingAddress') {
                xml.tag!('address') {
                  WorldPay.configuration.shipping_addresses.each do |attr|
                    val = instance_variable_get(:"@#{attr}").to_s

                    unless val.empty?
                      xml.tag!(attr.to_s) {
                        xml.text! val
                      }
                    end
                  end
                } # address
              } # shippingAddress
            end # has_shipping_address?
          }
        end # Submit
      end # Payment Service
      xml.target!
    end

    def create!
      # Create client!
      @client ||= ::HTTPClient.new

      # Set authentization
      @client.set_auth(
        WorldPay.configuration.url,
        WorldPay.configuration.merchant_id,
        WorldPay.configuration.password
      )

      # Get response!
      @create_payment_response = @client.request(:post, WorldPay.configuration.url, nil, get_payment_request, content_type: 'text/xml')

      # Invalid authentication?!
      if @create_payment_response.body.include? 'This request requires HTTP authentication'
        fail 'Invalid payment credentials'
      end

      # Validate response
      check_payment_create_response
    end

    # Get redirect url
    def get_payment_url
      # Create payment when no url presents
      create! unless @redirect_url

      # Return url
      @redirect_url
    end

    private

      def validate_payment_attributes
        # Check presence of necessary attributes
      end

      def check_payment_create_response
        # validate response
        body = Nokogiri::XML.parse(@create_payment_response.body)

        # Error attribute?!
        error = body.css('error').first
        fail error.children.first.content if error

        # Validate order status!
        order_status = body.css('orderStatus').first
        fail 'Invalid order code' if !order_status || order_status['orderCode'].to_s != @order_code.to_s

        # Get reference
        reference = body.css('reference').first
        fail 'Reference not exists' if !reference || reference.content.blank?

        @redirect_url = reference.content
      end

      def has_shipping_address?
        # Get patterns
        patterns = WorldPay.configuration.valid_address_patterns
        patterns.each do |pattern|
          status = true

          # Check variables
          pattern.each do |attr|
            status = false if instance_variable_get(:"@#{attr}").blank?
          end

          # Return true, pattern fits!
          return true if status
        end

        # No pattern matches
        return false
      end
  end
end
