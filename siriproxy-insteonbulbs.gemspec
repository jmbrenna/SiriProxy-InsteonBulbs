# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "siriproxy-insteonbulbs"
  s.version     = "0.0.1" 
  s.authors     = ["microcool"]
  s.email       = [""]
  s.homepage    = ""
  s.summary     = %q{test}
  s.description = %q{test}

  s.rubyforge_project = "siriproxy-example"

  s.files         = `git ls-files 2> /dev/null`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/* 2> /dev/null`.split("\n")
  s.executables   = `git ls-files -- bin/* 2> /dev/null`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
    s.add_runtime_dependency "nokogiri"
end