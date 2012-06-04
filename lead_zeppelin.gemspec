# -*- encoding: utf-8 -*-
require File.expand_path('../lib/lead_zeppelin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kyle Drake"]
  gem.email         = ["kyledrake@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "lead_zeppelin"
  gem.require_paths = ["lib"]
  gem.version       = LeadZeppelin::VERSION
  gem.add_dependency 'multi_json'
  gem.add_dependency 'json'
  gem.add_dependency 'connection_pool'

#  gem.add_dependency 'jruby-openssl'
#  gem.add_development_dependency 'debugger'
#  gem.add_development_dependency 'pry'
end