module WorldPay
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      WorldPay.configure_from_rails
    end
  end
end
