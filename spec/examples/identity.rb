require "some_file"
$:.unshift("directory")

module RubyScribe
  module Example
    def module_method
      add + something
      subtract - something
      self.array << "append"
    end
  end
  
  class MyClass < Subclass
    attr_accessor :no_parathesis
    call_method("Apartness")
  end
end