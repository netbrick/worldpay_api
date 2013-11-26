require 'httpclient'

module WorldPay
  class Payment
    # Attributes
    attr_reader :version, :merchant_id, :order_code, :description, :ammount_value, :ammount_currency_code, :ammount_exponent, :order_content

    # Payments ARRAYS!
    attr_reader :payment_method_mask_include, :payment_method_mask_exclude

    # Shopper informations
    attr_reader :shopper_email_address

    # Client
    attr_reader :client

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
      @payment_method_mask_include ||= [ "ALL" ]
      @payment_method_mask_exclude ||= []

      # Version & Merchant ID
      @version     ||= WorldPay.configuration.payment_service_version
      @merchant_id ||= WorldPay.configuration.merchant_id
    end

    # All payments!
    def all_payments
      @payment_method_mask_include = [ "ALL" ]
      @payment_method_mask_exclude = []
    end

    # Only online payments
    def online_payments
      @payment_method_mask_include = [ "ONLINE" ]
      @payment_method_mask_exclude = []
    end


    # Get XML payment request!
    def get_payment_request
      # Init builder
      xml = Builder::XmlMarkup.new(:indent => 2)

      # XML
      xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

      # Doctype!
      xml.declare! :DOCTYPE, :paymentService, :PUBLIC, "-//WorldPay/DTD WorldPay PaymentService v1//EN", "http://dtd.worldpay.com/paymentService_v1.dtd"

      # Payment service - version & merchant_id
      xml.tag!("paymentService", { :version => @version, :merchantCode => @merchant_id }) {

        # Submit
        xml.tag!("submit") {

          # Order
          xml.tag!("order", { :orderCode => @order_code }) {
            # Description
            xml.description(@description)

            # Ammount
            xml.tag!("amount", { :value => @ammount_value, :currencyCode => @ammount_currency_code, :exponent => @ammount_exponent })

            # Order Content - CDATA!
            xml.tag!("orderContent") { xml.cdata!(@order_content) }

            # Payment method mask
            xml.tag!("paymentMethodMask") {
              @payment_method_mask_include.each { |method| xml.tag!("include", { :code => method }) }
              @payment_method_mask_exclude.each { |method| xml.tag!("exclude", { :code => method }) }
            }

            # Shoper payment
            xml.tag!("shopper") {
              xml.shopperEmailAddress(@shopper_email_address)
            }

            # Shipping address?
            if has_shipping_address?
              xml.tag!("shippingAddress") {
                xml.tag!("address") {
                  WorldPay.configuration.shipping_addresses.each do |attr|
                    val = instance_variable_get(:"@#{attr}").to_s
                  
                    if !val.empty?
                      xml.tag!(attr.to_s) {
                        xml.text! val
                      }
                    end
                  end 
                } # address
              } # shippingAddress
            end # has_shipping_address?
          }
        }  
      }
      xml.target!
    end

    def create!
      # Create client!
      @client ||= HttpClient.new

      # Set authentization
      @client.set_auth(WorldPay.configuration.url, WorldPay.configuration.merchant_id, WorldPay.configuration.password)

      # Get response!
      @client.request(:post, WorldPay.configuration.url, nil, get_payment_request, {:content_type => "text/xml"})
    end

    private
      def has_shipping_address?
        # Some value from address?
        WorldPay.configuration.shipping_addresses.each do |attr|
          return true unless instance_variable_get(:"@#{attr}").blank?
        end

        # No address filed!
        return false
      end
  end
end
