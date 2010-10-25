require "thor"

module RubyScribe
  class Runner < Thor
    default_task :cat
    
    desc :cat, "Takes a single ruby file, parses it, and outputs the scribed version."
    def cat(path)
      sexp = RubyParser.new.parse(File.read(path))
      puts RubyScribe::Emitter.new.emit(sexp)
    end
    
    desc :replace, "Takes a single file or multiple files, parses them, then replaces the original file(s) with the scribed version."
    def replace(*paths)
      paths.each do |path|
        sexp = RubyParser.new.parse(File.read(path))
        
        File.open(path, "w") do |file|
          file.write RubyScribe::Emitter.new.emit(sexp)
          file.flush
        end
      end
    end
  end
end
