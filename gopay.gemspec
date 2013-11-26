# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib/", __FILE__)

require "worldpay/version"

Gem::Specification.new do |s|
  s.name        = "worldpay"
  s.version     = WorldPay::VERSION
  s.authors     = %w("strnadj")
  s.email       = %w("jan.strnadek@netbrick.eu")
  s.homepage    = "https://github.com/netbrick/worldpay_api"
  s.summary     = "A little gem making WorldPay payments easy"
  s.description = "WorldPay payment library"

  s.rubyforge_project = "worldpay"

  # Dependency
  s.add_dependency "httpclient", "~> 2.3.4.1"
  s.add_dependency "nokogiri"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- test/*`.split("\n")
  s.require_paths = ["lib"]
end
