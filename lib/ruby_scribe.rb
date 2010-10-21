require "rubygems"
require "active_support"

module RubyScribe
  include ActiveSupport::Autoload
  
  autoload :Emitter, "ruby_scribe/emitter"
  autoload :EmitterHelpers, "ruby_scribe/emitter_helpers"
  autoload :Preprocess, "ruby_scribe/preprocessor"
end