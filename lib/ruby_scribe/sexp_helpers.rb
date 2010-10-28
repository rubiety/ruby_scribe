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
      
      # TODO:
      # def method!(name, arguments = nil, body = nil)
      #   
      # end
      # 
      # def call!(name, arguments = nil, body = nil)
      #   
      # end
      # 
      # def args!(arguments = [])
      #   
      # end
      
      
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
      
      def call?(name = nil)
        kind == :call && 
        (name.nil? || match_expression(body[1], name))
      end
      
      def conditional?(options = {})
        kind == :if && 
        (options[:type].nil? || match_conditional_type(self, options[:type]))
      end
      
      def case?
        kind == :case
      end
      
      
      protected
      
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
    end
  end
end
