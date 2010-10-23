module RubyScribe
  module EmitterHelpers
    def indents
      @indents ||= []
    end
    
    def indent_level
      indents.inject(0) {|b,i| b + i } || 0
    end
    
    def indent(level = 2)
      indents.push(level)
      output = yield
      indents.pop
      output
    end
    
    def nl(text = "")
      "\n" + (" " * indent_level) + text
    end
  end
end