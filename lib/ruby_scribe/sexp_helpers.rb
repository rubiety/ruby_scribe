require "active_support/concern"

module RubyScribe
  
  # Various helpers for matching and constructing S-expressions without having to deal with 
  # array soup
  module SexpHelpers
    extend ActiveSupport::Concern
    
    module ClassMethods
      def module!(name, body = nil)
        s(:module, generate_module_or_class_name(name), ensure_scope_wrapped(body))
      end
      
      def class!(name, extends = nil, body = nil)
        s(:class, generate_module_or_class_name(name), generate_class_extend_from(extends), ensure_scope_wrapped(body))
      end
      
      def method!(name, arguments = nil, body = nil)
        s(:defn, name.to_sym, method_args!(arguments), method_body!(body))
      end
      
      def method_on!(on, name, arguments = nil, body = nil)
        s(:defs, on, name.to_sym, method_args!(arguments), method_body!(body))
      end
      
      def method_args!(arguments = nil)
        arguments ||= []
        options = arguments.extract_options!
        
        s(*([:args] + arguments.map(&:to_sym))).tap do |args|
          args.push s(*([:block] + options.map {|k, v| s(:lasgn, k.to_sym, v) })) if options && !options.empty?
        end
      end
      
      def method_body!(body = nil)
        if body.is_a?(Sexp) && body.kind == :scope
          body
        elsif body.is_a?(Sexp) && body.kind == :block
          ensure_scope_wrapped(body)
        elsif body.is_a?(Sexp)
          method_body!(s(:block, body))
        elsif body.is_a?(Array)
          method_body!(s(*([:block] + body)))
        else
          method_body!(s(:block, s(:nil)))
        end
      end
      
      def call!(name, arguments = nil, body = nil)
        call_on!(nil, name.to_sym, arguments, body)
      end
      
      def call_on!(receiver, name, arguments = nil, body = nil)
        s(:call, receiver, name.to_sym, call_args!(arguments))
      end
      
      def call_args!(arguments = nil)
        arguments ||= []
        
        if arguments.is_a?(Sexp) && arguments.kind == :arglist
          arguments
        elsif arguments.is_a?(Sexp)
          s(:arglist, arguments)
        elsif arguments.is_a?(Array)
          s(*([:arglist] + arguments))
        else
          s(:arglist)
        end
      end
      
      
      protected
      
      def generate_module_or_class_name(name)
        if name.nil?
          nil
        elsif name.is_a?(Sexp) or name.is_a?(Symbol)
          name
        elsif name.to_s !~ /::/
          name.to_sym
        else
          RubyParser.new.parse(name)
        end
      end
      
      def generate_class_extend_from(name)
        if name.nil?
          nil
        elsif name.is_a?(Sexp) or name.is_a?(Symbol)
          name
        else
          RubyParser.new.parse(name)
        end
      end
      
      def ensure_scope_wrapped(sexp)
        if sexp.is_a?(Sexp) && sexp.kind == :scope
          sexp
        elsif sexp.nil?
          s(:scope)
        else
          s(:scope, sexp)
        end
      end
    end
    
    module InstanceMethods
      def kind
        sexp_type.to_sym
      end
      
      def body
        sexp_body
      end
      
      def name
        case kind
        when :call
          body[1]
        when :lasgn, :iasgn, :class, :module
          body[0]
        when :iter
          body[0].name
        else
          nil
        end
      end
      
      def receiver
        case kind
        when :call
          body[0]
        else
          nil
        end
      end
      
      def arguments
        case kind
        when :call, :defs
          body[2]
        when :defn, :iter
          body[1]
        else
          nil
        end
      end
      
      def to_args
        emit_as_args_array(arguments)
      end
      
      def block
        case kind
        when :defn
          strip_scope_wrapper(body[2])
        when :defs
          strip_scope_wrapper(body[3])
        when :class
          strip_scope_wrapper(body[2])
        when :module
          strip_scope_wrapper(body[1])
        else
          nil
        end
      end
      
      def call!(name, arguments = nil, body = nil)
        Sexp.call_on!(self, name, arguments, body)
      end
      
      def module?(name = nil)
        kind == :module && 
        (name.nil? || match_expression(body[0], name))
      end
      
      def class?(name = nil, options = {})
        kind == :class && 
        (name.nil? || match_expression(body[0], name))
      end
      
      def method?(name = nil)
        (kind == :defn && (name.nil? || match_expression(body[0], name))) || 
        (kind == :defs && (name.nil? || match_expression(body[1], name)))
      end
      
      def call?(name = nil, options = {})
        call_without_block?(name, options) || call_with_block?(name, options)
      end
      
      def call_without_block?(name = nil, options = {})
        kind == :call && 
        (name.nil? || match_expression(body[1], name)) &&
        (options[:arguments].nil? || match_arguments_expression(self, options[:arguments])) &&
        (!options[:block])
      end
      
      def call_with_block?(name = nil, options = {})
        kind == :iter && body[0] && body[0].kind == :call &&
        (name.nil? || match_expression(body[0].name, name)) &&
        (options[:arguments].nil? || match_arguments_expression(body[0], options[:arguments])) &&
        (options[:block].nil? || match_arguments_expression(self, options[:block]))
      end
      
      def rescue?
        kind == :rescue
      end
      
      def conditional?(options = {})
        kind == :if && 
        (options[:type].nil? || match_conditional_type(self, options[:type]))
      end
      
      def case?
        kind == :case
      end
      
      
      protected
      
      def emit_as_args_array(e)
        return e unless e.is_a?(Sexp)
        
        case e.kind
        when :arglist, :args
          e.body.map {|c| emit_as_args_array(c) }.flatten
        when :lasgn
          [e.body[0]]
        when :masgn
          e.body[0].body.map {|c| emit_as_args_array(c) }.flatten
        when :lit
          [e.body[0]]
        else
          [e]
        end
      end
      
      def match_expression(match_against, expression)
        case expression
        when String
          match_against.to_s == expression
        when Regexp
          match_against.to_s =~ expression
        when Array
          expression.map(&:to_s).include?(match_against.to_s)
        else
          false
        end
      end
      
      def match_arguments_expression(match_against, expression)
        case expression
        when Fixnum
          expression == match_against.to_args.size
        when Range
          expression.include?(match_against.to_args.size)
        when Array
          expression == match_against.to_args
        when TrueClass
          match_against.to_args.size > 0
        when FalseClass
          match_against.to_args.size == 0
        else
          false
        end
      end
      
      def match_conditional_type(match_against, expression)
        case expression
        when :if
          !match_against.body[1].nil? && match_against.body[2].nil?
        when :unless
          match_against.body[1].nil? && !match_against.body[2].nil?
        when :if_else
          !match_against.body[1].nil? && !match_against.body[2].nil?
        else
          false
        end
      end
      
      def strip_scope_wrapper(e)
        e.kind == :scope ? strip_scope_wrapper(e.body[0]) : e
      end
    end
  end
end
