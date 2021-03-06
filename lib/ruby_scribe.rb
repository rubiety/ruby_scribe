require "rubygems"
require "bundler/setup"
require "ruby_parser"

require "ruby_scribe/sexp_helpers"
require "ruby_scribe/emitter_helpers"
require "ruby_scribe/emitter_config"
require "ruby_scribe/emitter"
require "ruby_scribe/ext/sexp"

Dir[File.join(File.dirname(__FILE__), "ruby_scribe/transformers/**/*.rb")].each do |file|
  require file
end
