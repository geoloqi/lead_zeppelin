# -*- encoding: utf-8 -*-
require File.expand_path('../lib/lead_zeppelin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kyle Drake"]
  gem.email         = ["kyledrake@gmail.com"]
  gem.description   = %q{Thread-safe, multi-application APNS client}
  gem.summary       = %q{Thread-safe, multi-application APNS client that makes it easier to develop notification software for the APNS service.}
  gem.homepage      = "https://github.com/geoloqi/lead_zeppelin"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "lead_zeppelin"
  gem.require_paths = ["lib"]
  gem.version       = LeadZeppelin::VERSION
  gem.add_dependency 'multi_json'
  gem.add_dependency 'json'
end