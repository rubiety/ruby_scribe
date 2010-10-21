module RubyScribe
  # Takes a proprocessed S-expression and emits formatted Ruby code
  class Emitter
    include EmitterHelpers
    
    def initialize
      @indents = []
      @output = ""
    end
    
    def emit(sexp)
      case sexp.sexp_type
      when :block
        emit_block(sexp)
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
      when :str, :lit, :true, :false
        emit_token(sexp)
      else
        emit_unknown_expression(sexp)
      end
    end
    
    
    protected
    
    def emit_block(sexp)
      sexp.sexp_body.each do |child|
        sline
        emit(child)
        eline
      end
    end
    
    def emit_class_definition(sexp)
      line "class #{sexp.sexp_body[0]}"
      
      indent do
        emit sexp.sexp_body[2].sexp_body[0]
      end
      
      line "end"
      line
    end
    
    def emit_module_definition(sexp)
      line "module #{sexp.sexp_body[0]}"
      
      indent do
        emit sexp.sexp_body[2].sexp_body[0]
      end
      
      line "end"
      line
    end
    
    def emit_method_definition(sexp)
      line
      line "def #{sexp.sexp_body[0]}"
      
      indent do
        sexp.sexp_body[2].sexp_body[0].sexp_body.each do |child|
          sline
          emit(child)
          eline
        end
        line
      end
      
      line "end"
    end
    
    def emit_method_call(sexp)
      segment "#{sexp.sexp_body[1]}("
      emit_method_argument_list(sexp.sexp_body[2])
      segment ")"
    end
    
    def emit_method_argument_list(sexp)
      sexp.sexp_body.each_with_index do |arg, i|
        segment ", " unless i == 0
        emit(arg)
      end
    end
    
    def emit_conditional_block(sexp)
      case sexp.sexp_type
      when :if
        sline "if "
        emit sexp.sexp_body[0]
        eline
        
        indent do
          sline
          emit sexp.sexp_body[1]
          eline
        end
      
        line "end"
      else :unless
        sline "unless "
        emit sexp.sexp_body[0]
        eline
        
        indent do
          sline
          emit sexp.sexp_body[1]
          eline
        end
        
        line "end"
      end
    end
    
    def emit_loop_block(sexp)
      
    end
    
    def emit_assignment_expression(sexp)
      
    end
    
    def emit_block_invocation(sexp)
      
    end
    
    def emit_token(sexp)
      case sexp.sexp_type
      when :str
        segment '"' + sexp.sexp_body[0] + '"'
      when :lit
        segment sexp.sexp_body[0].to_s
      when :true
        segment "true"
      when :false
        segment "false"
      else
        segment sexp.sexp_body
      end
    end
    
    def emit_unknown_expression(sexp)
      
    end
  end
end