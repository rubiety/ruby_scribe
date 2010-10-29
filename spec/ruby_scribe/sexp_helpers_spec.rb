require "spec_helper"

describe RubyScribe::SexpHelpers do
  context "generating" do
    context "module" do
      describe "with string name" do
        subject { Sexp.module!("MyModule") }
        it { should == s(:module, :MyModule, s(:scope)) }
      end
      
      describe "with string colonized name" do
        subject { Sexp.module!("Namespace::MyModule") }
        it { should == s(:module, s(:colon2, s(:const, :Namespace), :MyModule), s(:scope)) }
      end
      
      describe "with string double-colonized name" do
        subject { Sexp.module!("Double::Namespace::MyModule") }
        it { should == s(:module, s(:colon2, s(:colon2, s(:const, :Double), :Namespace), :MyModule), s(:scope)) }
      end
      
      describe "with sexp name" do
        subject { Sexp.module!(s(:colon2, s(:const, :Namespace), :MyModule)) }
        it { should == s(:module, s(:colon2, s(:const, :Namespace), :MyModule), s(:scope)) }
      end
      
      describe "with single-statement body passed" do
        subject { Sexp.module!("MyModule", s(:lit, 1)) }
        it { should == s(:module, :MyModule, s(:scope, s(:lit, 1))) }
      end
      
      describe "with single-statement scoped body passed" do
        subject { Sexp.module!("MyModule", s(:scope, s(:lit, 1))) }
        it { should == s(:module, :MyModule, s(:scope, s(:lit, 1))) }
      end
      
      describe "with block body passed" do
        subject { Sexp.module!("MyModule", s(:block, s(:call, nil, :one, s(:arglist)), s(:call, nil, :two, s(:arglist)))) }
        it { should == s(:module, :MyModule, s(:scope, s(:block, s(:call, nil, :one, s(:arglist)), s(:call, nil, :two, s(:arglist))))) }
      end
    end
    
    context "class" do
      describe "with string name" do
        subject { Sexp.class!("MyClass") }
        it { should == s(:class, :MyClass, nil, s(:scope)) }
      end
      
      describe "with string colonized name" do
        subject { Sexp.class!("Namespace::MyClass") }
        it { should == s(:class, s(:colon2, s(:const, :Namespace), :MyClass), nil, s(:scope)) }
      end
      
      describe "with string double-colonized name" do
        subject { Sexp.class!("Double::Namespace::MyClass") }
        it { should == s(:class, s(:colon2, s(:colon2, s(:const, :Double), :Namespace), :MyClass), nil, s(:scope)) }
      end
      
      describe "with sexp name" do
        subject { Sexp.class!(s(:colon2, s(:const, :Namespace), :MyClass)) }
        it { should == s(:class, s(:colon2, s(:const, :Namespace), :MyClass), nil, s(:scope)) }
      end
      
      describe "with single-statement body passed" do
        subject { Sexp.class!("MyClass", nil, s(:lit, 1)) }
        it { should == s(:class, :MyClass, nil, s(:scope, s(:lit, 1))) }
      end
      
      describe "with single-statement scoped body passed" do
        subject { Sexp.class!("MyClass", nil, s(:scope, s(:lit, 1))) }
        it { should == s(:class, :MyClass, nil, s(:scope, s(:lit, 1))) }
      end
      
      describe "with block body passed" do
        subject { Sexp.class!("MyClass", nil, s(:block, s(:call, nil, :one, s(:arglist)), s(:call, nil, :two, s(:arglist)))) }
        it { should == s(:class, :MyClass, nil, s(:scope, s(:block, s(:call, nil, :one, s(:arglist)), s(:call, nil, :two, s(:arglist))))) }
      end
      
      describe "extending a string name" do
        subject { Sexp.class!("MyClass", "Base") }
        it { should == s(:class, :MyClass, s(:const, :Base), s(:scope)) }
      end
      
      describe "extending a colonized string name" do
        subject { Sexp.class!("MyClass", "Base::Two") }
        it { should == s(:class, :MyClass, s(:colon2, s(:const, :Base), :Two), s(:scope)) }
      end
      
      describe "extending an sexp name" do
        subject { Sexp.class!("MyClass", s(:const, :Base)) }
        it { should == s(:class, :MyClass, s(:const, :Base), s(:scope)) }
      end
    end
    
    context "method" do
      
    end
    
    context "method call" do
      
    end
  end
  
  context "an s-expression for" do
    context "module" do
      subject { s(:module, :MyModule, s(:scope, s(:lit, 1))) }
      it { should be_module }
      it { should be_module("MyModule") }
      it { should be_module(/dul/) }
      it { should be_module([:MyModule, :YourModule]) }
    end
    
    context "class" do
      subject { s(:class, :MyClass, nil, s(:scope, s(:lit, 1))) }
      it { should be_class }
      it { should be_class("MyClass") }
      it { should be_class(/las/) }
      it { should be_class([:MyClass, :YourClass]) }
    end
    
    context "instance method" do
      subject { s(:defn, :my_method, s(:args, :arg), s(:scope, s(:block, s(:lit, 1)))) }
      it { should be_method }
      it { should be_method("my_method") }
      it { should be_method(/met/) }
      it { should be_method([:my_method, :your_method]) }
      specify { subject.to_args.should == [:arg] }
      
      describe "with two arguments" do
        subject { s(:defn, :my_method, s(:args, :one, :two), s(:scope, s(:block, s(:lit, 1)))) }
        specify { subject.to_args.should == [:one, :two] }
      end
    end
    
    context "class method" do
      subject { s(:defs, s(:self), :my_method, s(:args, :arg), s(:scope, s(:block, s(:lit, 1)))) }
      it { should be_method }
      it { should be_method("my_method") }
      it { should be_method(/met/) }
      it { should be_method([:my_method, :your_method]) }
    end
    
    context "method call" do
      describe "with one argument" do
        subject { s(:call, nil, :invoke, s(:arglist, s(:lit, 1))) }
        it { should be_call }
        it { should be_call("invoke") }
        it { should be_call(/vok/) }
        it { should be_call([:invoke, :another]) }
        it { should be_call("invoke", :arguments => true) }
        it { should be_call("invoke", :arguments => 1) }
        it { should_not be_call("invoke", :arguments => 2) }
        it { should_not be_call("invoke", :block => true) }
      end
      
      describe "with block" do
        subject { s(:iter, s(:call, nil, :each, s(:arglist)), s(:lasgn, :i), s(:lit, 1)) }
        it { should be_call }
        it { should be_call("each") }
        it { should be_call("each", :block => true) }
        it { should be_call("each", :block => 1) }
        it { should_not be_call("each", :block => 2) }
        specify { subject.to_args.should == [:i] }
      end
      
      describe "with block (2 arguments) and 1 method argument" do
        subject { s(:iter, s(:call, nil, :inject, s(:arglist, s(:lit, 1))), s(:masgn, s(:array, s(:lasgn, :b), s(:lasgn, :i))), s(:lit, 1)) }
        it { should be_call(nil, :block => true) }
        it { should be_call(nil, :arguments => true) }
        it { should be_call(nil, :arguments => 1, :block => 2) }
        it { should_not be_call(nil, :arguments => 2, :block => 2) }
        specify { subject.to_args.should == [:b, :i] }
      end
    end
    
    context "conditional" do
      describe "if-else" do
        subject { s(:if, s(:true), s(:lit, 1), s(:lit, 2)) }
        it { should be_conditional(:type => :if_else) }
      end
      
      describe "if" do
        subject { s(:if, s(:true), s(:lit, 1), nil) }
        it { should be_conditional(:type => :if) }
      end
      
      describe "unless" do
        subject { s(:if, s(:true), nil, s(:lit, 2)) }
        it { should be_conditional(:type => :unless) }
      end
    end
    
    context "case statement" do
      subject { s(:case, nil, s(:when, s(:array, s(:true)), s(:lit, 1)), s(:lit, 2)) }
      it { should be_case }
    end
  end
end