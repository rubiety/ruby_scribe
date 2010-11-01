require "active_support/core_ext"

module RubyScribe
  # Takes a proprocessed S-expression and emits formatted Ruby code
  class Emitter
    include EmitterHelpers
    include EmitterConfig
    
    def emit(e)
      return "" unless e
      return e if e.is_a?(String)
      return e.to_s if e.is_a?(Symbol)
      
      case e.kind
      when :block
        emit_block(e)
      when :scope
        emit_scope(e)
      when :ensure
        emit_rescue_ensure_wrapper(e)
      when :rescue
        emit_rescue(e)
      when :resbody
        emit_rescue_body(e)
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
      when :cvasgn, :gasgn
        emit_class_variable_assignment(e)
      when :masgn
        emit_multiple_assignment(e)
      when :cdecl
        emit_constant_declaration(e)
      when :if
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
      when :op_asgn1, :op_asgn2
        emit_optional_assignment_expression(e)
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
      return "" if e.body.first == s(:nil)
      
      # Special case for handling rescue blocks around entire methods (excluding the indent):
      return emit_method_rescue(e.body.first) if e.body.first.rescue? && e.body.size == 1
      
      e.body.map do |child|
        emit_block_member_prefix(e.body, child) + 
        emit(child)
      end.join(nl)
    end
    
    # TODO: Clean up block member prefix emitting
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
      
      if current_member.conditional? && [:block_if, :block_unless].include?(determine_if_type(current_member))
        return nl
      elsif previous_member.conditional? && [:block_if, :block_unless].include?(determine_if_type(previous_member))
        return nl
      end
      
      if previous_member.call? && grouped_methods.include?(previous_member.name.to_s) && (!current_member.call? || (current_member.call? && current_member.name != previous_member.name))
        return nl
      end
      
      if current_member.call? && grouped_methods.include?(current_member.name.to_s) && (!previous_member.call? || (previous_member.call? && previous_member.name != current_member.name))
        return nl
      end
      
      ""
    end
    
    def emit_scope(e)
      emit(e.body.first)
    end
    
    def emit_rescue_ensure_wrapper(e)
      rescue_sexp = e.body.first
      block = rescue_sexp.body.size == 1 ? nil : rescue_sexp.body.first
      resbody = rescue_sexp.body.size == 1 ? rescue_sexp.body.first : rescue_sexp.body.second
      ensure_sexp = e.body.second
      
      "begin" + indent { nl + emit(block) } +
      emit(resbody) +
      nl("ensure") + 
      indent { nl + emit(ensure_sexp) } +
      nl("end")
    end
    
    def emit_rescue(e, force_long = false)
      block = e.body.size == 1 ? nil : e.body.first
      resbody = e.body.size == 1 ? e.body.first : e.body.second
      
      if !force_long && e.line == resbody.line && block.kind != :block && resbody && resbody.body.second && resbody.body.second.kind != :block
        "#{emit(block)} rescue #{emit(resbody.body.second)}"
      else
        "begin" + indent { nl + emit(block) } +
        emit(resbody) +
        nl("end")
      end
    end
    
    def emit_rescue_body(e)
      nl("rescue ".gsub(/ $/, '')) + 
      indent { nl + emit(e.body.second) }
    end
    
    def emit_method_rescue(e)
      block = e.body.size == 1 ? nil : e.body.first
      resbody = e.body.size == 1 ? e.body.first : e.body.second
      
      emit(block) + 
      indent(-2) { emit(resbody) }
    end
    
    def emit_class_definition(e)
      emit_comments(e.comments) + 
      "#{e.kind} #{emit(e.body.first)}" + 
      (e.body.second ? " < #{emit(e.body.second)}" : "") +
      indent { nl + emit(e.body.third) } + 
      nl("end")
    end
    
    def emit_self_class_definition(e)
      "class << #{emit(e.body.first)}" + 
      indent { nl + emit(e.body.second) } + 
      nl("end")
    end
    
    def emit_module_definition(e)
      emit_comments(e.comments) +
      "module #{emit(e.body.first)}" + 
      indent { nl + emit(e.body.second) } + 
      nl("end")
    end
    
    def emit_method_definition(e)
      emit_comments(e.comments) + 
      "def #{e.body.first}" + 
      (e.body.second.body.empty? ? "" : "(#{emit(e.body.second)})") +
      indent { nl + emit(e.body.third) } + 
      nl("end")
    end
    
    def emit_method_with_receiver_definition(e)
      emit_comments(e.comments) +
      "def #{emit(e.body.first)}.#{e.body.second}" + 
      (e.body.third.body.empty? ? "" : "(#{emit(e.body.third)})") +
      indent { nl + emit(e.body[3]) } + 
      nl("end")
    end
    
    def emit_method_argument_list(e)
      [].tap do |array|
        e.body.each do |child|
          if child.is_a?(Sexp) and child.kind == :block
            child.body.each do |body_child|
              array[array.index(body_child.body.first)] = emit(body_child)
            end
          else
            array << child
          end
        end
      end.join(", ")
    end
    
    def emit_method_call(e)
      return emit_method_call_hash_access(e) if e.body.second == :[]
      return emit_method_call_hash_assignment(e) if e.body.second == :[]=
      
      emit_method_call_receiver(e) + 
      emit_method_call_name(e) + 
      emit_method_call_arguments(e)
    end
    
    def emit_method_call_receiver(e)
      if e.body.first && syntactic_methods.include?(e.body.second.to_s)
        "#{emit(e.body.first)} "
      elsif e.body.first
        "#{emit(e.body.first)}."
      else
        ""
      end
    end
    
    def emit_method_call_name(e)
      emit(e.body.second)
    end
    
    def emit_method_call_arguments(e)
      if e.body.third.body.empty?
        ""
      elsif methods_without_parenthesis.include?(e.body.second.to_s)
        " " + emit(e.body.third)
      elsif syntactic_methods.include?(e.body.second.to_s)
        " " + emit(e.body.third)
      else
        "(" + emit(e.body.third) + ")"
      end
    end
    
    def emit_method_call_hash_access(e)
      emit(e.body.first) + "[" + emit(e.body.third) + "]"
    end
    
    def emit_method_call_hash_assignment(e)
      emit(e.body.first) + "[" + emit(e.body.third.body.first) + "] = " + emit(e.body.third.body.second)
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
      return emit_method_call(e) if ['[]='].include?(e.body.second.to_s)
      
      emit(e.body.first) + "." + e.body.second.to_s.gsub(/=$/, "") + " = " + emit(e.body.third)
    end
    
    def emit_class_variable_assignment(e)
      emit(e.body.first) + " = " + emit(e.body.second)
    end
    
    def emit_multiple_assignment(e)
      left = e.body.first.body
      right = e.body.second.body
      
      left.map {|c| c.body.first }.join(", ") + " = " + right.map {|c| emit(c) }.join(", ")
    end
    
    def emit_constant_declaration(e)
      emit(e.body.first) + " = " + emit(e.body.second)
    end
    
    def determine_if_type(e)
      if e.body.second && e.body.third && e.body.first.line == e.body.second.try(:line) && e.line == e.body.third.try(:line)
        :ternary
      elsif e.body.second && !e.body.third && e.line == e.body.second.line && e.body.second.kind != :block
        :dangling_if
      elsif !e.body.second && e.body.third && e.line == e.body.third.line && e.body.third.kind != :block
        :dangling_unless
      elsif e.body.second
        :block_if
      elsif e.body.third
        :block_unless
      end
    end
    
    def emit_conditional_block(e)
      case determine_if_type(e)
      when :ternary
        "#{emit(e.body.first)} ? #{emit(e.body.second || s(:nil))} : #{emit(e.body.third || s(:nil))}"
      when :dangling_if
        "#{emit(e.body.second)} if #{emit(e.body.first)}"
      when :dangling_unless
        "#{emit(e.body.third)} unless #{emit(e.body.first)}"
      when :block_if
        "if #{emit(e.body.first)}" + indent { nl + emit(e.body.second) } + 
        emit_conditional_else_block(e.body.third) +  
        nl("end")
      when :block_unless
        "unless #{emit(e.body.first)}" + indent { nl + emit(e.body.third) } +
        nl("end")
      end
    end
    
    def emit_conditional_else_block(e)
      return "" unless e
      
      if e.kind == :if
        nl("elsif #{emit(e.body.first)}") + indent { nl + emit(e.body.second) } + 
        emit_conditional_else_block(e.body.third)
      else
        nl("else") + indent { nl + emit(e) }
      end
    end
    
    def emit_case_statement(e)
      "case #{emit(e.body.first)}".gsub(/ $/, '') + e.body[1..-2].map {|c| emit(c) }.join + emit_case_else_statement(e.body[-1]) + nl("end")
    end
    
    def emit_case_when_statement(e)
      nl("when #{emit_case_when_argument(e.body.first)}") + indent { nl + emit(e.body.second) }
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
      "#{e.kind} #{emit(e.body.first)}" + 
      indent { nl + emit(e.body.second) } + 
      nl("end")
    end
    
    def emit_for_block(e)
      "for #{e.body.second.body.first} in #{emit(e.body.first)}" + 
      indent { nl + emit(e.body.third) } + 
      nl("end")
    end
    
    def emit_assignment_expression(e)
      "#{e.body.first} = #{emit(e.body.second)}"
    end
    
    def emit_optional_assignment_expression(e)
      emit(e.body.first) + "[#{emit(e.body.second)}] #{emit(e.body.third)}= " + emit(e.body[3])
    end
    
    def emit_optional_assignment_or_expression(e)
      emit(e.body.first) + " ||= " + emit(e.body.second.body.second)
    end
    
    def emit_optional_assignment_and_expression(e)
      emit(e.body.first) + " &&= " + emit(e.body.second.body.second)
    end
    
    def emit_binary_expression(e)
      "(" + emit(e.body.first) + " " + 
      (e.kind == :and ? "&&" : "||") + 
      " " + emit(e.body.second) + ")"
    end
    
    def emit_block_invocation(e)
      emit(e.body.first) + emit_block_invocation_body(e)
    end
    
    def emit_block_invocation_body(e)
      # If it's on the same line, it should probably be shorthand form:
      if e.line == e.body.third.try(:line)
        " {#{emit_block_invocation_arguments(e)} #{emit(e.body.third)} }"
      else
        " do #{emit_block_invocation_arguments(e)}".gsub(/ +$/, '') + 
        indent { nl + emit(e.body.third) } + 
        nl("end")
      end
    end
    
    def emit_block_invocation_arguments(e)
      if e.body.second
        "|" + emit_assignments_as_arguments(e.body.second) + "|"
      else
        ""
      end
    end
    
    def emit_assignments_as_arguments(e)
      if e.kind == :masgn
        e.body.first.body.map {|c| emit_assignments_as_arguments(c) }.join(", ")
      elsif e.kind == :lasgn
        e.body.first.to_s
      elsif e.kind == :splat
        "*" + emit_assignments_as_arguments(e.body.first)
      end
    end
    
    def emit_defined_invocation(e)
      "defined?(#{emit(e.body.first)})"
    end
    
    def emit_token(e)
      case e.kind
      when :str
        '"' + e.body.first + '"'
      when :lit
        e.body.first.inspect
      when :const
        e.body.first.to_s
      when :lvar
        e.body.first.to_s
      when :ivar
        e.body.first.to_s
      when :cvar
        e.body.first.to_s
      when :not
        "!" + emit(e.body.first)
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
        "alias #{emit(e.body.first)} #{emit(e.body.second)}"
      when :block_pass
        "&" + emit(e.body.first)
      when :splat
        "*" + emit(e.body.first)
      when :colon2
        "#{emit(e.body.first)}::#{emit(e.body.second)}"
      when :colon3
        "::#{emit(e.body.first)}"
      when :dot2
        "#{emit(e.body.first)}..#{emit(e.body.second)}"
      when :hash
        "{" + emit_hash_body(e) + "}"
      when :array
        "[" + e.body.map {|c| emit(c)}.join(", ") + "]"
      when :nth_ref, :back_ref
        "$" + e.body.first.to_s
      when :gvar
        e.body.first.to_s
      when :dstr
        '"' + literalize_strings(e.body).map {|c| emit(c) }.join + '"'
      when :dregx
        '/' + literalize_strings(e.body).map {|c| emit(c) }.join + '/'
      when :evstr
        '#{' + emit(e.body.first) + '}'
      when :xstr
        '`' + emit(e.body.first) + '`'
      when :dxstr
        '`' + literalize_strings(e.body).map {|c| emit(c) }.join + '`'
      when :dsym
        ':"' + literalize_strings(e.body).map {|c| emit(c) }.join + '"'
      when :match3
        emit(e.body.second) + " =~ " + emit(e.body.first)
      when :cvdecl
        emit(e.body.first.to_s) + " = " + emit(e.body.second)
      else
        emit_unknown_expression(e)
      end
    end
    
    def emit_hash_body(e, force_short = false)
      grouped = e.body.in_groups_of(2)
      
      if !force_short && grouped.size >= long_hash_key_size
        indent(2) { nl + grouped.map {|g| "#{emit(g[0])} => #{emit(g[1])}" }.join("," + nl) } + nl
      else
        grouped.map {|g| "#{emit(g[0])} => #{emit(g[1])}" }.join(", ")
      end
    end
    
    def emit_unknown_expression(e)
      nl("## RubyScribe-UNKNOWN: #{e.kind} ##")
    end
  end
end