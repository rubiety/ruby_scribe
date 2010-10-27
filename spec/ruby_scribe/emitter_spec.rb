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
      %{class Scribe::Animal\n  \nend}.should emit_itself
    end
    
    specify "eigenclass should emit itself" do
      %{class << self\n  \nend}.should emit_itself
    end
  end
  
  context "module definition" do
    specify "simple module should emit itself" do
      %{module Animal\n  \nend}.should emit_itself
    end
    
    specify "namespaced class should emit itself" do
      %{module Scribe::Animal\n  \nend}.should emit_itself
    end
  end
  
  context "rescue definition" do
    specify "rescue all should emit itself" do
      %{begin\n  \nrescue\n  \nend}.should emit_itself
    end
    
    specify "rescue all with ensure should emit itself" do
      %{begin\n  \nrescue\n  \nensure\n  nil\nend}.should emit_itself
    end
    
    specify "method-wide rescue should emit itself" do
      %{def method\n  \nrescue\n  \nend}.should emit_itself
    end
    
    specify "dangling rescue should emit itself" do
      %{do_something rescue nil}.should emit_itself
    end
    
    specify "rescuing with exception class should emit itself" do
      pending do
        %{begin\n  \nrescue StandardError\n  \nend}.should emit_itself
      end
    end
    
    specify "rescuing with multiple exception classes should emit itself" do
      pending do
        %{begin\n  \nrescue StandardError\n  \nend}.should emit_itself
      end
    end
    
    specify "rescuing with exception class and target variable should emit itself" do
      pending do
        %{begin\n  \nrescue StandardError => e\n  \nend}.should emit_itself
      end
    end
  end
  
  context "method definition" do
    specify "without arguments should emit itself" do
      %{def method\n  \nend}.should emit_itself
    end
    
    specify "with one argument should emit itself" do
      %{def method(one)\n  \nend}.should emit_itself
    end
    
    specify "with multiple arguments should emit itself" do
      %{def method(one, two)\n  \nend}.should emit_itself
    end
    
    specify "with optional arguments should emit itself" do
      %{def method(one = 1, two = {})\n  \nend}.should emit_itself
    end
    
    specify "with block argument should emit itself" do
      %{def method(one, &two)\n  \nend}.should emit_itself
    end
  end
  
  context "method call" do
    specify "without arguments should emit itself" do
      %{method}.should emit_itself
    end
    
    specify "with one argument should emit itself" do
      %{method("One")}.should emit_itself
    end
    
    specify "with multiple arguments should emit itself" do
      %{method("One", 2)}.should emit_itself
    end
    
    specify "with last argument as a hash should emit itself" do
      %{method("One", :option => :one)}.should emit_itself
    end
    
    specify "with block should emit itself" do
      %{method do\n  \nend}.should emit_itself
    end
  end
  
  context "case statement" do
    specify "with argument should emit itself" do
      %{case something\nwhen 1\n  \nend}.should emit_itself
    end
    
    specify "without argument should emit itself" do
      %{case\nwhen 1 == 1\n  \nend}
    end
    
    specify "with else block should emit itself" do
      %{case something\nwhen 1\n  \nelse\n  2\nend}.should emit_itself
    end
  end
  
  context "assignment" do
    specify "to global variable should emit itself" do
      %{$variable = 1}.should emit_itself
    end
    
    specify "to simple local variable should emit itself" do
      %{variable = 1}.should emit_itself
    end
    
    specify "to instance variable should emit itself" do
      %{@variable = 1}.should emit_itself
    end
    
    specify "to class variable should emit itself" do
      %{@@variable = 1}.should emit_itself
    end
    
    specify "to class variable inside a method should emit itself" do
      %{def hi\n  @@variable = 1\nend}.should emit_itself
    end
    
    specify "to multiple variables should emit itself" do
      %{variable_1, variable_2 = 1, 2}.should emit_itself
    end
    
    specify "with or should emit itself" do
      %{@variable ||= 1}.should emit_itself
    end
    
    specify "with and should emit itself" do
      %{@variable &&= 1}.should emit_itself
    end
    
    specify "with hash should emit itself" do
      %{@variable["something"] ||= 1}.should emit_itself
    end
  end
  
  context "conditionals" do
    specify "simple block if should emit itself" do
      %{if true\n  something\nend}.should emit_itself
    end
    
    specify "simple block unless should emit itself" do
      %{unless true\n  something\nend}.should emit_itself
    end
    
    specify "simple block if else should emit itself" do
      %{if true\n  something\nelse\n  something_else\nend}.should emit_itself
    end
    
    specify "dangling if should emit itself" do
      %{something if true}.should emit_itself
    end
    
    specify "dangling unless should emit itself" do
      %{something unless true}.should emit_itself
    end
    
    specify "ternary if should emit itself" do
      %{something ? true : false}.should emit_itself
    end
  end
  
  context "looping expression definition" do
    specify "while should emit itself" do
      %{while true\n  \nend}.should emit_itself
    end
    
    specify "until should emit itself" do
      %{until true\n  \nend}.should emit_itself
    end
    
    specify "for in array should emit itself" do
      %{for something in array\n  \nend}.should emit_itself
    end
  end
  
  context "binary expressions" do
    specify "|| should emit itself" do
      %{(one || two)}.should emit_itself
    end
    
    specify "&& should emit itself" do
      %{(one && two)}.should emit_itself
    end
  end
  
  context "unary expressions" do
    specify "!something should emit itself" do
      %{!something}.should emit_itself
    end
  end
  
  context "return statement" do
    specify "with no argument should emit itself" do
      %{return}.should emit_itself
    end
    
    specify "with single argument should emit itself" do
      %{return 1}.should emit_itself
    end
    
    specify "with multiple arguments should emit itself" do
      %{return [1, 2]}.should emit_itself
    end
  end
  
  context "literals" do
    specify "short string should emit itself" do
      %{"my string"}.should emit_itself
    end
    
    specify "short string with interpolation should emit itself" do
      '"my #{test} string"'.should emit_itself
    end
    
    specify "heredoc string should emit itself" do
      pending do
        %{<<EOF\n  my strong\n  line 2\n  line 3\n  line 4\nEOF}.should emit_itself
      end
    end
    
    specify "short hash should emit itself" do
      %{{:hash => :one, :another => :two}}.should emit_itself
    end
    
    specify "long hash should emit itself" do
      %{{\n  :key1 => :value1,\n  :key2 => :value2,\n  :key3 => :value3,\n  :key4 => :value4,\n  :key5 => :value5,\n  :key6 => :value6\n}}.should emit_itself
    end
    
    specify "range with two dots should emit itself" do
      %{1..10}.should emit_itself
    end
    
    specify "range with three dots should emit itself" do
      %{1...10}.should emit_itself
    end
    
    specify "regular expression should emit itself" do
      %{/[a-zA-Z]$/}.should emit_itself
    end
    
    specify "regular expression with interpolation should emit itself" do
      '/[a-Z#{something}]/'.should emit_itself
    end
    
    specify "__FILE__ should emit itself" do
      pending("requires a patch to ruby_parser which cannot parse this") do
        %{__FILE__}.should emit_itself
      end
    end
    
    specify "__LINE__ should emit itself" do
      pending("requires a patch to ruby_parser which cannot parse this") do
        %{__LINE__}.should emit_itself
      end
    end
    
    specify "numeric reference should emit itself" do
      %{$1}.should emit_itself
    end
    
    specify "backreference should emit itself" do
      %{$&}.should emit_itself
    end
  end
end
