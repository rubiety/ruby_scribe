module RubyScribe
  module EmitterHelpers
    def indent(level = 2)
      @original_indent = @indent
      @indent += level
      yield
      @indent = @original_indent
    end
    
    def outdent(level = 2)
      indent(-level)
    end
    
    def line
      
    end
    
    def multiline
      
    end
  end
end