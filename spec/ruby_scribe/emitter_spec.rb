require "spec_helper"

## Relying on RubyParser here to emit what we expect, but much more readable than manually composite s-expressions

describe RubyScribe::Emitter do
  before { @emitter = RubyScribe::Emitter.new }
  
  context "class definition" do
    specify "simple class should emit itself" do
      %{class Animal\n  \nend}.should emit_itself
    end
    
    specify "extended class should emit itself" do
      %{class Animal < Creature\n  \nend}.should emit_itself
    end
    
    specify "namespaced class should emit itself" do
      pending do
        %{class Scribe::Animal\n  \nend}.should emit_itself
      end
    end
    
    specify "eigenclass should emit itself" do
      pending do
        %{class << self\n  \nend}.should emit_itself
      end
    end
  end
  
  context "module definition" do
    specify "simple module should emit itself" do
      %{module Animal\n  \nend}.should emit_itself
    end
    
    specify "namespaced class should emit itself" do
      pending do
        %{module Scribe::Animal\n  \nend}.should emit_itself
      end
    end
  end
  
  context "rescue definition" do
    specify "rescue all should emit itself" do
      %{begin\n  \nrescue\n  \nend}.should emit_itself
    end
    
    specify "method-wide rescue should emit itself" do
      %{def method\n  \nrescue\n  \nend}.should emit_itself
    end
  end
  
  context "method definition" do
    specify "without arguments" do
      %{def method\n  \nend}.should emit_itself
    end
    
    specify "with one argument" do
      %{def method(one)\n  \nend}.should emit_itself
    end
    
    specify "with multiple arguments" do
      %{def method(one, two)\n  \nend}.should emit_itself
    end
    
    specify "with optional arguments" do
      %{def method(one = 1, two = {})\n  \nend}.should emit_itself
    end
    
    specify "with block argument" do
      %{def method(one, &two)\n  \nend}.should emit_itself
    end
  end
  
  context "method call" do
    specify "without arguments" do
      %{method}.should emit_itself
    end
    
    specify "with one argument" do
      %{method("One")}.should emit_itself
    end
    
    specify "with multiple arguments" do
      %{method("One", 2)}.should emit_itself
    end
    
    specify "with last argument as a hash" do
      %{method("One", :option => :one)}.should emit_itself
    end
    
    specify "with block" do
      %{method do\n  \nend}.should emit_itself
    end
  end
  
  context "case statement" do
    specify "with argument" do
      %{case something\nwhen 1\n  \nend}.should emit_itself
    end
    
    specify "without argument" do
      %{case\nwhen 1 == 1\n  \nend}
    end
    
    specify "with else block" do
      %{case something\nwhen 1\n  \nelse\n  2\nend}.should emit_itself
    end
  end
  
  context "attribute assignment" do
    specify "to simple local variable" do
      %{variable = 1}.should emit_itself
    end
    
    specify "to instance variable" do
      %{@variable = 1}.should emit_itself
    end
    
    specify "to multiple variables" do
      %{variable_1, variable_2 = 1, 2}.should emit_itself
    end
    
    specify "with or" do
      %{@variable ||= 1}.should emit_itself
    end
    
    specify "with and" do
      %{@variable &&= 1}.should emit_itself
    end
  end
  
  context "conditionals" do
    specify "simple block if" do
      %{if true\n  something\nend}.should emit_itself
    end
    
    specify "simple block unless" do
      %{unless true\n  something\nend}.should emit_itself
    end
    
    specify "simple block if else" do
      %{if true\n  something\nelse\n  something_else\nend}.should emit_itself
    end
    
    specify "dangling if" do
      %{something if true}.should emit_itself
    end
    
    specify "dangling unless" do
      %{something unless true}.should emit_itself
    end
    
    specify "ternary if" do
      %{something ? true : false}.should emit_itself
    end
  end
  
  context "looping expression definition" do
    specify "while" do
      %{while true\n  \nend}.should emit_itself
    end
    
    specify "until" do
      %{until true\n  \nend}.should emit_itself
    end
    
    specify "for in array" do
      %{for something in array\n  \nend}.should emit_itself
    end
  end
  
  context "binary expressions" do
    specify "||" do
      %{(one || two)}.should emit_itself
    end
    
    specify "&&" do
      %{(one && two)}.should emit_itself
    end
  end
  
  context "unary expressions" do
    specify "!something" do
      %{!something}.should emit_itself
    end
  end
end
