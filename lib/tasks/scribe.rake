namespace :scribe do
  desc "Run Scribe Examples"
  task :examples do
    $:.unshift(File.join(File.dirname(__FILE__), ".."))
    require "ruby_parser"
    require "ruby_scribe"
    require "pp"
    
    original_file = File.read(File.join(File.dirname(__FILE__), "../../spec/examples/simple_class_with_methods.rb"))
    sexp = RubyParser.new.parse(original_file)
    
    puts "Parsed S-Expresssion"
    puts "======================================"
    pp sexp
    puts
    
    puts "Original File"
    puts "======================================"
    puts original_file
    
    puts
    puts
    
    puts "Parsed File"
    puts "======================================"
    parsed_file = RubyScribe::Emitter.new.emit(sexp)
    puts parsed_file
  end
end