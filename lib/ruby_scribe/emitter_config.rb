module RubyScribe
  module EmitterConfig
    extend ActiveSupport::Concern
    
    included do
      class_inheritable_accessor :methods_without_parenthesis
      self.methods_without_parenthesis = %w(
        attr_accessor attr_reader attr_writer
        alias alias_method alias_attribute
        gem require extend include raise
        delegate autoload raise
        puts
      )

      class_inheritable_accessor :grouped_methods
      self.grouped_methods = %w(require attr_accessor autoload)
      
      class_inheritable_accessor :long_hash_key_size
      self.long_hash_key_size = 5
      
      class_inheritable_accessor :default_indent
      self.default_indent = 2
      
      class_inheritable_accessor :syntactic_methods
      self.syntactic_methods = ['+', '-', '<<', '==', '===', '>', '<']
    end
  end
end