require "active_support/core_ext"

module RubyScribe
  # Takes a proprocessed S-expression and emits formatted Ruby code
  class Emitter
    include EmitterHelpers
    
    cattr_accessor :methods_without_parenthesis
    self.methods_without_parenthesis = %w(require gem puts attr_accessor cattr_accessor)
    
    SYNTACTIC_METHODS = ['+', '-', '<<']
    
    def emit(e)
      return "" unless e
      return e if e.is_a?(String)
      return e.to_s if e.is_a?(Symbol)
      
      case e.kind
      when :block
        emit_block(e)
      when :scope
        emit_scope(e)
      when :rescue
        emit_rescue(e)
      when :module
        emit_module_definition(e)
      when :class
        emit_class_definition(e)
      when :sclass
        emit_self_class_definition(e)
      when :defn
        emit_method_definition(e)
      when :defs
        emit_method_with_receiver_definition(e)
      when :args
        emit_method_argument_list(e)
      when :call
        emit_method_call(e)
      when :arglist
        emit_argument_list(e)
      when :attrasgn
        emit_attribute_assignment(e)
      when :cdecl
        emit_constant_declaration(e)
      when :if, :unless
        emit_conditional_block(e)
      when :case
        emit_case_statement(e)
      when :when
        emit_case_when_statement(e)
      when :while, :until
        emit_loop_block(e)
      when :for
        emit_for_block(e)
      when :lasgn, :iasgn
        emit_assignment_expression(e)
      when :op_asgn_or
        emit_optional_assignment_expression(e)
      when :or, :and
        emit_binary_expression(e)
      when :iter
        emit_block_invocation(e)
      when :defined
        emit_defined_invocation(e)
      else
        emit_token(e)
      end || ""
    end
    
    
    protected
    
    def emit_comments(comments)
      comments ? (comments.split("\n").join(nl) + nl) : ""
    end
    
    def emit_block(e)
      return "" if e.body[0] == s(:nil)
      
      e.body.map do |child|
        emit_block_member_prefix(e.body, child) + 
        emit(child) +
        emit_block_member_suffix(e.body, child)
      end.join(nl)
    end
    
    def emit_block_member_prefix(members, current_member)
      ""
    end
    
    def emit_block_member_suffix(members, current_member)
      ""
    end
    
    def emit_scope(e)
      nl + emit(e.body[0])
    end
    
    def emit_rescue(e)
      "begin" + indent { nl + emit(e.body[0]) } +
      nl("rescue ") + indent { nl + emit(e.body[1].body[1]) } + 
      nl("end")
    end
    
    def emit_class_definition(e)
      emit_comments(e.comments) + 
      "#{e.kind} #{e.body[0]}" + 
      (e.body[1] ? " < #{emit(e.body[1])}" : "") +
      indent { emit(e.body[2]) } + 
      nl("end")
    end
    
    def emit_self_class_definition(e)
      "class << #{e.body[0]}" + 
      indent { nl + emit(e.body[1]) } + 
      nl("end")
    end
    
    def emit_module_definition(e)
      emit_comments(e.comments) +
      "#{e.kind} #{e.body[0]}" + 
      indent { emit(e.body[1]) } + 
      nl("end")
    end
    
    def emit_method_definition(e)
      emit_comments(e.comments) + 
      "def #{e.body[0]}" + 
      (e.body[1].body.empty? ? "" : "(#{emit(e.body[1])})") +
      indent { emit(e.body[2]) } + 
      nl("end")
    end
    
    def emit_method_with_receiver_definition(e)
      emit_comments(e.comments) +
      "def #{emit(e.body[0])}.#{e.body[1]}" + 
      (e.body[2].body.empty? ? "" : "(#{emit(e.body[2])})") +
      indent { emit(e.body[3]) } + 
      nl("end")
    end
    
    def emit_method_argument_list(e)
      e.body.map do |child|
        if child.is_a?(Sexp) and child.kind == :block
          emit(child.body[0])
        else
          child
        end
      end.join(", ")
    end
    
    def emit_method_call(e)
      return emit_method_call_hash_access(e) if e.body[1] == :[]
      return emit_method_call_hash_assignment(e) if e.body[1] == :[]=
      
      emit_method_call_receiver(e) + 
      emit_method_call_name(e) + 
      emit_method_call_arguments(e)
    end
    
    def emit_method_call_receiver(e)
      if e.body[0] && SYNTACTIC_METHODS.include?(e.body[1].to_s)
        "#{emit(e.body[0])} "
      elsif e.body[0]
        "#{emit(e.body[0])}."
      else
        ""
      end
    end
    
    def emit_method_call_name(e)
      emit(e.body[1])
    end
    
    def emit_method_call_arguments(e)
      if e.body[2].body.empty?
        ""
      elsif self.class.methods_without_parenthesis.include?(e.body[1].to_s)
        " " + emit(e.body[2])
      elsif SYNTACTIC_METHODS.include?(e.body[1].to_s)
        " " + emit(e.body[2])
      else
        "(" + emit(e.body[2]) + ")"
      end
    end
    
    def emit_method_call_hash_access(e)
      emit(e.body[0]) + "[" + emit(e.body[2]) + "]"
    end
    
    def emit_method_call_hash_assignment(e)
      emit(e.body[0]) + "[" + emit(e.body[2].body[0]) + "] = " + emit(e.body[2].body[1])
    end
    
    
    def emit_argument_list(e)
      e.body.map do |child|
        emit(child)
      end.join(", ")
    end
    
    def emit_attribute_assignment(e)
      return emit_method_call(e) if ['[]='].include?(e.body[1].to_s)
      
      emit(e.body[0]) + "." + e.body[1].to_s.gsub(/=$/, "") + " = " + emit(e.body[2])
    end
    
    def emit_constant_declaration(e)
      emit(e.body[0]) + " = " + emit(e.body[1])
    end
    
    def emit_conditional_block(e)
      "if #{emit(e.body[0])}" + indent { nl + emit(e.body[1]) } + 
      (e.body[2] ? (nl("else") + indent { nl + emit(e.body[2]) }) : "") + 
      nl("end")
    end
    
    def emit_case_statement(e)
      "case #{emit(e.body.first)}" + e.body[1..-1].map {|c| emit(c) }.join + nl("end")
    end
    
    def emit_case_when_statement(e)
      nl("when #{emit_case_when_argument(e.body.first)}") + indent { nl + emit(e.body[1]) }
    end
    
    def emit_case_when_argument(e)
      emit(e).gsub(/^\[/, '').gsub(/\]$/, '')
    end
    
    def emit_loop_block(e)
      "#{e.kind} #{e.body.first}" + 
      indent { emit(e.body[1]) } + 
      nl("end")
    end
    
    def emit_for_block(e)
      "for #{e.body[1].body[0]} in #{emit(e.body[0])}" + 
      indent { nl + emit(e.body[2]) } + 
      nl("end")
    end
    
    def emit_assignment_expression(e)
      "#{e.body[0]} = #{emit(e.body[1])}"
    end
    
    def emit_optional_assignment_expression(e)
      emit(e.body[0]) + " ||= " + emit(e.body[1].body[1])
    end
    
    def emit_binary_expression(e)
      emit(e.body[0]) + " " + 
      (e.kind == :and ? "&&" : "||") + 
      " " + emit(e.body[1])
    end
    
    def emit_block_invocation(e)
      emit(e.body[0]) + " do" + 
      indent { nl + emit(e.body[2]) } + 
      nl("end")
    end
    
    def emit_defined_invocation(e)
      "defined?(#{emit(e.body[0])})"
    end
    
    def emit_token(e)
      case e.kind
      when :str
        '"' + e.body[0] + '"'
      when :lit
        e.body[0].inspect
      when :const
        e.body[0].to_s
      when :lvar
        e.body[0].to_s
      when :ivar
        e.body[0].to_s
      when :not
        "!" + emit(e.body[0])
      when :true
        "true"
      when :false
        "false"
      when :nil
        "nil"
      when :self
        "self"
      when :zsuper
        "super"
      when :super
        "super(" + e.body.map {|c| emit(c) }.join(", ") + ")"
      when :yield
        "yield"
      when :next
        "next"
      when :retry
        "retry"
      when :return
        "return"
      when :block_pass
        "&" + emit(e.body[0])
      when :splat
        "*" + emit(e.body[0])
      when :colon2
        "#{emit(e.body[0])}::#{e.body[1].to_s}"
      when :hash
        ":hash => :value"
      when :array
        "[" + e.body.map {|c| emit(c)}.join(", ") + "]"
      when :gvar
        e.body[0].to_s
      when :dstr
        '"' + literalize_strings(e.body).map {|c| emit(c) }.join + '"'
      when :evstr
        '#{' + emit(e.body[0]) + '}'
      when :xstr
        '`' + emit(e.body[0]) + '`'
      when :dxstr
        '`' + literalize_strings(e.body).map {|c| emit(c) }.join + '`'
      when :dsym
        ':"' + literalize_strings(e.body).map {|c| emit(c) }.join + '"'
      when :match3
        emit(e.body[1]) + " =~ " + emit(e.body[0])
      when :cvdecl
        emit(e.body[0].to_s) + " = " + emit(e.body[1])
      else
        emit_unknown_expression(e)
      end
    end
    
    def emit_unknown_expression(e)
      nl("## UNKNOWN: #{e.kind} ##")
    end
  end
end