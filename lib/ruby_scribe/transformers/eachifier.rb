module RubyScribe
  module Transformers
    class Eachifier < Transformer
      def transform(e)
        if e.is_a?(Sexp) && e.kind == :for
          transform_for_to_each(e)
        else
          super
        end
      end
      
      def transform_for_to_each(e)
        s(:iter, 
          s(:call, e.body[0], :each, s(:arglist)), 
          e.body[1],
          e.body[2]
        )
      end
    end
  end
end