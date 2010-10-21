require "rubygems"
require "active_support"

module RubyScribe
  include ActiveSupport::Autoload
  
  autoload :Strategy, "ruby_scribe/strategy"
end