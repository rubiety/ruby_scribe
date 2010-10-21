module RubyScribe
  # Takes a raw S-expression and proprocesses it
  class Preprocessor
    def initialize(sexp)
      @sexp = sexp
    end
    
    def proprocess
      @sexp
    end
  end
end