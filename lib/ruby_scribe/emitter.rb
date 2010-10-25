require "active_support/core_ext"

module RubyScribe
  # Takes a proprocessed S-expression and emits formatted Ruby code
  class Emitter
    include EmitterHelpers
    
    cattr_accessor :methods_without_parenthesis
    self.methods_without_parenthesis = %w(require gem puts attr_accessor cattr_accessor delegate alias_method alias)
    
    SYNTACTIC_METHODS = ['+', '-', '<<', '==', '===', '>', '<']
    
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
      when :masgn
        emit_multiple_assignment(e)
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
        emit_optional_assignment_or_expression(e)
      when :op_asgn_and
        emit_optional_assignment_and_expression(e)
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
      comments.present? ? (comments.split("\n").join(nl) + nl) : ""
    end
    
    def emit_block(e)
      return "" if e.body[0] == s(:nil)
      
      # Special case for handling rescue blocks around entire methods (excluding the indent):
      return emit_method_rescue(e.body[0]) if e.body.size == 1 and e.body[0].kind == :rescue
      
      e.body.map do |child|
        emit_block_member_prefix(e.body, child) + 
        emit(child)
      end.join(nl)
    end
    
    def emit_block_member_prefix(members, current_member)
      previous_member_index = members.index(current_member) - 1
      previous_member = previous_member_index >= 0 ? members[previous_member_index] : nil
      return "" unless previous_member
      
      [
        [[:defn, :defs, :iter, :class, :module, :rescue], [:defn, :defs, :iter, :class, :module, :call, :rescue]],
        [[:call], [:defn, :defs, :iter, :class, :module]]
      ].each do |from, to|
        return nl if (from == :any || from.include?(previous_member.kind)) && (to == :any || to.include?(current_member.kind))
      end
      
      if current_member.kind == :if && [:block_if, :block_unless].include?(determine_if_type(current_member))
        return nl
      elsif previous_member.kind == :if && [:block_if, :block_unless].include?(determine_if_type(previous_member))
        return nl
      end
      
      ""
    end
    
    def emit_scope(e)
      emit(e.body[0])
    end
    
    def emit_rescue(e)
      "begin" + indent { nl + emit(e.body[0]) } +
      nl("rescue ") + indent { nl + emit(e.body[1].body[1]) } + 
      nl("end")
    end
    
    def emit_method_rescue(e)
      emit(e.body[0]) + 
      indent(-2) { nl("rescue ") } + 
      nl + emit(e.body[1].body[1])
    end
    
    def emit_class_definition(e)
      emit_comments(e.comments) + 
      "#{e.kind} #{e.body[0]}" + 
      (e.body[1] ? " < #{emit(e.body[1])}" : "") +
      indent { nl + emit(e.body[2]) } + 
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
      indent { nl + emit(e.body[1]) } + 
      nl("end")
    end
    
    def emit_method_definition(e)
      emit_comments(e.comments) + 
      "def #{e.body[0]}" + 
      (e.body[1].body.empty? ? "" : "(#{emit(e.body[1])})") +
      indent { nl + emit(e.body[2]) } + 
      nl("end")
    end
    
    def emit_method_with_receiver_definition(e)
      emit_comments(e.comments) +
      "def #{emit(e.body[0])}.#{e.body[1]}" + 
      (e.body[2].body.empty? ? "" : "(#{emit(e.body[2])})") +
      indent { nl + emit(e.body[3]) } + 
      nl("end")
    end
    
    def emit_method_argument_list(e)
      [].tap do |array|
        e.body.each do |child|
          if child.is_a?(Sexp) and child.kind == :block
            child.body.each do |body_child|
              array[array.index(body_child.body[0])] = emit(body_child)
            end
          else
            array << child
          end
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
        if child == e.body[-1] && child.kind == :hash
          emit_hash_body(child)
        else
          emit(child)
        end
      end.join(", ")
    end
    
    def emit_attribute_assignment(e)
      return emit_method_call(e) if ['[]='].include?(e.body[1].to_s)
      
      emit(e.body[0]) + "." + e.body[1].to_s.gsub(/=$/, "") + " = " + emit(e.body[2])
    end
    
    def emit_multiple_assignment(e)
      left = e.body[0].body
      right = e.body[1].body
      
      left.map {|c| c.body[0] }.join(", ") + " = " + right.map {|c| emit(c) }.join(", ")
    end
    
    def emit_constant_declaration(e)
      emit(e.body[0]) + " = " + emit(e.body[1])
    end
    
    def determine_if_type(e)
      if e.body[1] && e.body[2] && e.body[0].line == e.body[1].try(:line) && e.line == e.body[2].try(:line)
        :terinary
      elsif e.body[1] && !e.body[2] && e.line == e.body[1].line && e.body[1].kind != :block
        :dangling_if
      elsif !e.body[1] && e.body[2] && e.line == e.body[2].line && e.body[2].kind != :block
        :dangling_unless
      elsif e.body[1]
        :block_if
      elsif e.body[2]
        :block_unless
      end
    end
    
    def emit_conditional_block(e)
      case determine_if_type(e)
      when :terinary
        "#{emit(e.body[0])} ? #{emit(e.body[1] || s(:nil))} : #{emit(e.body[2] || s(:nil))}"
      when :dangling_if
        "#{emit(e.body[1])} if #{emit(e.body[0])}"
      when :dangling_unless
        "#{emit(e.body[2])} unless #{emit(e.body[0])}"
      when :block_if
        "if #{emit(e.body[0])}" + indent { nl + emit(e.body[1]) } + 
        (e.body[2] ? (nl("else") + indent { nl + emit(e.body[2]) }) : "") + 
        nl("end")
      when :block_unless
        "unless #{emit(e.body[0])}" + indent { nl + emit(e.body[2]) } +
        nl("end")
      end
    end
    
    def emit_case_statement(e)
      "case #{emit(e.body.first)}" + e.body[1..-2].map {|c| emit(c) }.join + emit_case_else_statement(e.body[-1]) + nl("end")
    end
    
    def emit_case_when_statement(e)
      nl("when #{emit_case_when_argument(e.body.first)}") + indent { nl + emit(e.body[1]) }
    end
    
    def emit_case_else_statement(e)
      if e
        nl("else") + indent { nl + emit(e) }
      else
        ""
      end
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
    
    def emit_optional_assignment_or_expression(e)
      emit(e.body[0]) + " ||= " + emit(e.body[1].body[1])
    end
    
    def emit_optional_assignment_and_expression(e)
      emit(e.body[0]) + " &&= " + emit(e.body[1].body[1])
    end
    
    def emit_binary_expression(e)
      emit(e.body[0]) + " " + 
      (e.kind == :and ? "&&" : "||") + 
      " " + emit(e.body[1])
    end
    
    def emit_block_invocation(e)
      emit(e.body[0]) + emit_block_invocation_body(e)
    end
    
    def emit_block_invocation_body(e)
      # If it's on the same line, it should probably be shorthand form:
      if e.line == e.body[2].try(:line)
        " {#{emit_block_invocation_arguments(e)} #{emit(e.body[2])} }"
      else
        " do #{emit_block_invocation_arguments(e)}".gsub(/ +$/, '') + 
        indent { nl + emit(e.body[2]) } + 
        nl("end")
      end
    end
    
    def emit_block_invocation_arguments(e)
      if e.body[1]
        "|" + emit_assignments_as_arguments(e.body[1]) + "| "
      else
        ""
      end
    end
    
    def emit_assignments_as_arguments(e)
      if e.kind == :masgn
        e.body[0].body.map {|c| emit_assignments_as_arguments(c) }.join(", ")
      elsif e.kind == :lasgn
        e.body[0].to_s
      elsif e.kind == :splat
        "*" + emit_assignments_as_arguments(e.body[0])
      end
    end
    
    def emit_defined_invocation(e)
      "defined?(#{emit(e.body[0])})"
    end
    
    def emit_token(e)
      case e.kind
      when :str
        "'" + e.body[0] + "'"
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
        "yield #{emit_argument_list(e)}".strip
      when :next
        "next"
      when :retry
        "retry"
      when :return
        "return #{emit_argument_list(e)}".strip
      when :alias
        "alias #{emit(e.body[0])} #{emit(e.body[1])}"
      when :block_pass
        "&" + emit(e.body[0])
      when :splat
        "*" + emit(e.body[0])
      when :colon2
        "#{emit(e.body[0])}::#{e.body[1].to_s}"
      when :hash
        "{" + emit_hash_body(e) + "}"
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
    
    def emit_hash_body(e)
      e.body.in_groups_of(2).map {|g| "#{emit(g[0])} => #{emit(g[1])}" }.join(", ")
    end
    
    def emit_unknown_expression(e)
      nl("## UNKNOWN: #{e.kind} ##")
    end
  end
end