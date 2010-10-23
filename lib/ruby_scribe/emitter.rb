module RubyScribe
  # Takes a proprocessed S-expression and emits formatted Ruby code
  class Emitter
    include EmitterHelpers
    
    def emit(e)
      return "" unless e
      
      case e.kind
      when :block
        emit_block(e)
      when :scope
        emit_scope(e)
      when :rescue
        emit_rescue(e)
      when :class, :module
        emit_class_definition(e)
      when :defn
        emit_method_definition(e)
      when :call
        emit_method_call(e)
      when :attrasgn
        emit_attribute_assignment(e)
      when :if, :unless
        emit_conditional_block(e)
      when :case
        emit_case_statement(e)
      when :when
        emit_case_when_statement(e)
      when :while, :until
        emit_loop_block(e)
      when :lasgn, :iasgn
        emit_assignment_expression(e)
      when :op_asgn1
        emit_optional_assignment_expression(e)
      when :iter
        emit_block_invocation(e)
      when :defined
        emit_defined_invocation(e)
      when :str, :lit, :lvar, :ivar, :const, :true, :false, :colon2, :hash
        emit_token(e)
      else
        emit_unknown_expression(e)
      end || ""
    end
    
    
    protected
    
    def emit_block(e)
      e.body.map do |child|
        nl + emit(child)
      end.join
    end
    
    def emit_scope(e)
      emit(e.body.first)
    end
    
    def emit_rescue(e)
      "begin" + indent { emit(e.body[0]) } +
      nl("rescue") + indent { emit(e.body[1][1]) } + 
      nl("end")
    end
    
    def emit_class_definition(e)
      nl + nl("#{e.kind} #{e.body.first}") + indent { emit(e.body[2]) } + nl("end")
    end
    
    def emit_method_definition(e)
      nl("def #{e.body[1]}") + 
      indent { emit(e.body[2]) } + 
      nl("end") + nl
    end
    
    def emit_method_call(e)
      (e.body.second || "") + 
      "(#{emit(e.body[2])})"
    end
    
    def emit_attribute_assignment(e)
      e.body[0][0].to_s + "." + e.body[1].to_s.gsub(/=$/, "") + " = " + emit(e.body[2])
    end
    
    def emit_argument_list(e)
      "".tap do |s|
        e.body.each_with_index do |arg, i|
          segment ", " unless i == 0
          s << emit(arg)
        end
      end
    end
    
    def emit_conditional_block(e)
      "#{e.kind} #{e.body.first}" + emit(e.body[1]) + 
      nl("else") + indent { emit(e.body[2]) } + 
      nl("end")
    end
    
    def emit_case_statement(e)
      "case #{emit(e.body.first)}" + e.body[1..-1].map {|c| emit(c) } + nl("end")
    end
    
    def emit_case_when_statement(e)
      nl("when #{emit(e.body.first)}") + indent { emit(e.body[1]) }
    end
    
    def emit_loop_block(e)
      "#{e.kind} #{e.body.first}" + 
      indent { emit(e.body[1]) } + 
      nl("end")
    end
    
    def emit_assignment_expression(e)
      "#{e.body[0]} = #{emit(e.body[1])}"
    end
    
    def emit_optional_assignment_expression(e)
      
    end
    
    def emit_block_invocation(e)
      e.body[0] + " do" + 
      indent { emit(e.body[2]) } + 
      nl("end")
    end
    
    def emit_defined_invocation(e)
      "defined?(:#{e.body[0]})"
    end
    
    def emit_token(e)
      case e.kind
      when :str
        '"' + e.body[0] + '"'
      when :lit
        ":" + e.body[0].to_s
      when :const
        e.body[0].to_s
      when :lvar
        e.body[0].to_s
      when :ivar
        e.body[0].to_s
      when :true
        "true"
      when :false
        "false"
      when :colon2
        "#{emit(e.body[0])}::#{e.body[1].to_s}"
      when :hash
        ":hash => :value"
      else
        e.body.inspect
      end
    end
    
    def emit_unknown_expression(e)
      
    end
  end
end