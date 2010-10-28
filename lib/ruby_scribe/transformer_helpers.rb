module RubyScribe
  module TransformerHelpers
    def sexp?(e)
      e.is_a?(Sexp)
    end
  end
end