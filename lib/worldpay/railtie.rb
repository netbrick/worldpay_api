# -*- mode:ruby; coding:utf-8; -*-
module WorldPay
  # Rails ext
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      WorldPay.configure_from_rails
    end
  end
end
