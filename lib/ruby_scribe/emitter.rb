module RubyScribe
  # Takes a proprocessed S-expression and emits formatted Ruby code
  class Emitter
    include EmitterHelpers
    
    def initialize
      @indents = []
      @output = ""
    end
    
    def emit(sexp)
      return unless sexp
      
      case sexp.sexp_type
      when :block
        emit_block(sexp)
      when :rescue
        emit_rescue(sexp)
      when :class
        emit_class_definition(sexp)
      when :module
        emit_module_definition(sexp)
      when :defn
        emit_method_definition(sexp)
      when :call
        emit_method_call(sexp)
      when :attrasgn
        emit_attribute_assignment(sexp)
      when :if, :unless
        emit_conditional_block(sexp)
      when :case
        emit_case_statement(sexp)
      when :while, :until
        emit_loop_block(sexp)
      when :lasgn, :iasgn
        emit_assignment_expression(sexp)
      when :op_asgn1
        emit_optional_assignment_expression(sexp)
      when :iter
        emit_block_invocation(sexp)
      when :defined
        emit_defined_invocation(sexp)
      when :str, :lit, :lvar, :ivar, :const, :true, :false, :colon2, :hash
        emit_token(sexp)
      else
        emit_unknown_expression(sexp)
      end
      @output
    end
    
    
    protected
    
    def emit_block(sexp)
      sexp.sexp_body.each do |child|
        sline
        emit(child)
        eline
      end
    end
    
    def emit_rescue(sexp)
      eline "begin"

      indent do
        emit(sexp.sexp_body[0])
      end
      
      resbody = sexp.sexp_body[1].sexp_body
      line "rescue #{resbody[0].inspect}"
      
      indent do
        emit(resbody[1])
      end
      
      line "end"
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
      line
      line "module #{sexp.sexp_body[0]}"
      
      indent do
        emit sexp.sexp_body[1].sexp_body[0]
      end
      
      line "end"
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
      segment "#{sexp.sexp_body[1]}"
      
      if sexp.sexp_body[2].sexp_body[0]
        segment "("
        emit_argument_list(sexp.sexp_body[2])
        segment ")"
      end
    end
    
    def emit_attribute_assignment(sexp)
      segment sexp.sexp_body[0][0].to_s
      segment "."
      segment sexp.sexp_body[1].to_s.gsub(/=$/, "")
      segment " = "
      emit_argument_list(sexp.sexp_body[2])
    end
    
    def emit_argument_list(sexp)
      sexp.sexp_body.each_with_index do |arg, i|
        segment ", " unless i == 0
        emit(arg)
      end
    end
    
    def emit_conditional_block(sexp)
      segment "#{sexp.sexp_type} "
      emit sexp.sexp_body[0]
      eline
      
      indent do
        sline
        emit sexp.sexp_body[1]
        eline
      end
      
      if sexp.sexp_body[2]
        line "else"
        indent do
          sline
          emit sexp.sexp_body[2]
          eline
        end
      end
      
      sline "end"
    end
    
    def emit_case_statement(sexp)
      segment "case "
      emit sexp.sexp_body[0]
      eline
      sexp.sexp_body[1..-1].each do |child|
        emit_case_when_statement child
      end
    end
    
    def emit_case_when_statement(sexp)
      return unless sexp
      
      sline "when "
      emit sexp.sexp_body[0]
      eline
      emit sexp.sexp_body[1]
    end
    
    def emit_loop_block(sexp)
      sline "#{sexp.sexp_type} "
      emit sexp.sexp_body[0]
      eline
      
      indent do
        sline
        emit sexp.sexp_body[1]
        eline
      end
      
      line "end"
    end
    
    def emit_assignment_expression(sexp)
      segment "#{sexp.sexp_body[0]} = "
      emit sexp.sexp_body[1]
    end
    
    def emit_optional_assignment_expression(sexp)
      emit sexp.sexp_body[0]
      segment "["
      emit_argument_list sexp.sexp_body[1]
      segment "] "
      segment sexp.sexp_body[2].to_s
      segment "= "
      emit sexp.sexp_body[3]
    end
    
    def emit_block_invocation(sexp)
      emit sexp.sexp_body[0]
      
      if sexp.sexp_body[2].sexp_type == :block
        eline " do"
        
        indent do
          sline
          emit sexp.sexp_body[2]
          eline
        end
        
        line "end"
      else
        segment " { "
        emit sexp.sexp_body[2]
        eline " }"
      end
    end
    
    def emit_defined_invocation(sexp)
      segment "defined?(:"
      emit sexp.sexp_body[0]
      segment ")"
    end
    
    def emit_token(sexp)
      case sexp.sexp_type
      when :str
        segment '"' + sexp.sexp_body[0] + '"'
      when :lit
        segment ":" + sexp.sexp_body[0].to_s
      when :const
        segment sexp.sexp_body[0].to_s
      when :lvar
        segment sexp.sexp_body[0].to_s
      when :ivar
        segment sexp.sexp_body[0].to_s
      when :true
        segment "true"
      when :false
        segment "false"
      when :colon2
        emit sexp.sexp_body[0]
        segment "::"
        segment sexp.sexp_body[1].to_s
      when :hash
        sexp.sexp_body.in_groups_of(2) do |group|
          emit(group[0])
          segment " => "
          emit(group[1])
        end
      else
        segment sexp.sexp_body.to_s
      end
    end
    
    def emit_unknown_expression(sexp)
      
    end
  end
end