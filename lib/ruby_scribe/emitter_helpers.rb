module RubyScribe
  module EmitterHelpers
    def indent_level
      @indents.inject(0) {|b,i| b + i } || 0
    end
    
    def indent(level = 2)
      @indents.push(level)
      yield
      @indents.pop
    end
    
    def outdent(level = 2, &block)
      indent(-level, &block)
    end
    
    def line(s = "")
      @output << (" " * indent_level)
      @output << s
      @output << "\n"
    end
    
    def sline(s = "")
      @output << (" " * indent_level)
      @output << s
    end
    
    def eline(s = "")
      @output << s
      @output << "\n"
    end
    
    def segment(s = "")
      @output << s
    end
  end
end