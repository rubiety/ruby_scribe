# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ruby_scribe/version"

Gem::Specification.new do |s|
  s.name        = "ruby_scribe"
  s.version     = RubyScribe::VERSION  
  s.author      = "Ben Hughes"
  s.email       = "ben@railsgarden.com"
  s.homepage    = "http://github.com/rubiety/ruby_scribe"
  s.summary     = "Generates formatted ruby code from S-expressions (like from ruby_parser)."
  s.description = "A ruby formatting tool that takes S-expression as input and intelligently outputs formatted Ruby code."
  
  s.executables = ["rubyscribe"]
  s.files        = Dir["{lib,spec}/**/*", "[A-Z]*", "init.rb"]
  s.require_path = "lib"
  
  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.4"
  
  s.add_dependency("thor", ["~> 0.13"])
  s.add_dependency("activesupport", ["~> 3.0.10"])
  s.add_dependency("i18n", ["~> 0.6.0"])
  s.add_dependency("ruby_parser", ["~> 2.0.6"])
  s.add_development_dependency("rspec", ["~> 2.0"])
end
