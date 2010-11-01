module RubyScribe
  module EmitterConfig
    extend ActiveSupport::Concern
    
    included do
      attr_accessor :methods_without_parenthesis
      attr_accessor :grouped_methods
      attr_accessor :long_hash_key_size
      attr_accessor :default_indent
      attr_accessor :syntactic_methods
    end
    
    def initialize
      self.grouped_methods = %w(require attr_accessor autoload)
      self.long_hash_key_size = 5
      self.default_indent = 2
      self.syntactic_methods = ['+', '-', '<<', '==', '===', '>', '<']
      
      self.methods_without_parenthesis = %w(
        attr_accessor attr_reader attr_writer
        alias alias_method alias_attribute
        gem require extend include raise
        delegate autoload raise
        puts
      )
    end
  end
end