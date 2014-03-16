# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rflow/version"

Gem::Specification.new do |s|
  s.name        = "rflow"
  s.version     = RFlow::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9'
  s.authors     = ["Michael L. Artz"]
  s.email       = ["michael.artz@redjack.com"]
  s.homepage    = ""
  s.summary     = %q{A Ruby flow-based programming framework}
  s.description = %q{A Ruby flow-based programming framework that utilizes ZeroMQ for component connections and Avro for serialization}

  s.rubyforge_project = "rflow"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'uuidtools', '~> 2.1'
  s.add_dependency 'log4r', '~> 1.1'

  s.add_dependency 'sqlite3', '~> 1.3'
  s.add_dependency 'activerecord', '~> 3.0'

  s.add_dependency 'avro', '1.7.5'
  s.add_dependency 'em-zeromq', "~> 0.4.2"

  s.add_development_dependency 'rspec', '~> 2.6'
  s.add_development_dependency 'rake', '>= 0.8.7'
  #s.add_development_dependency 'rcov', '= 0.9.9' # Not 1.9.2 compatible
end