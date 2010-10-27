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
  
  class Test
    @@class_variable = 1
  end
  
  class MyClass < Subclass
    attr_accessor :no_parathesis
    
    call_method("Apartness")
    
    single_line_block {|a| a.do_something }
  end
  
  if a == 1
    1
  elsif a > 3
    2
  else
    3
  end
  
  if a == 1
    1
  else
    if a > 3
      2
    else
      3
    end
    
    do_something_now
  end
end