module RubyScribe
  # Takes a proprocessed S-expression and emits formatted Ruby code
  class Emitter
    include EmitterHelpers
    
    def initialize
      @indent = 0
      @output = ""
    end
    
    def emit(sexp)
      case sexp.sexp_type
      when :class
        emit_class_definition(sexp)
      when :module
        emit_module_definition(sexp)
      when :defn
        emit_method_definition(sexp)
      when :call
        emit_method_call(sexp)
      when :if, :unless
        emit_conditional_block(sexp)
      when :while, :until
        emit_loop_block(sexp)
      when :lasgn
        emit_assignment_expression(sexp)
      when :iter
        emit_block_invocation(sexp)
      else
        emit_unknown_expression(sexp)
      end
    end
    
    protected
    
    def emit_class_definition(sexp)
      
    end
    
    def emit_module_definition(sexp)
      
    end
    
    def emit_method_definition(sexp)
      
    end
    
    def emit_conditional_block(sexp)
      
    end
    
    def emit_loop_block(sexp)
      
    end
    
    def emit_assignment_expression(sexp)
      
    end
    
    def emit_block_invocation(sexp)
      
    end
    
    def emit_unknown_expression(sexp)
      
    end
  end
end