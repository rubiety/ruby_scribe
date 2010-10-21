namespace :scribe do
  desc "Run Scribe Examples"
  task :examples do
    $:.unshift(File.join(File.dirname(__FILE__), ".."))
    require "ruby_parser"
    require "ruby_scribe"
    
    original_file = File.read(File.join(File.dirname(__FILE__), "../../spec/examples/simple_class_with_methods.rb"))
    puts "Original File"
    puts "======================================"
    puts original_file
    
    puts
    puts
    
    sexp = RubyParser.new.parse(original_file)
    parsed_file = RubyScribe::Strategy.new.process(sexp)
    
    puts "Parsed File"
    puts "======================================"
    puts parsed_file
  end
end