#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/pops'

# relative to this spec file (./) does not work as this file is loaded by rspec
require File.join(File.dirname(__FILE__), '/parser_rspec_helper')

describe "egrammar parsing function calls" do
  include ParserRspecHelper

  context "When parsing calls as statements" do
    context "in top level scope" do
      it "foo()" do
        dump(parse("foo()")).should == "(invoke foo)"
      end

      it "notice bar" do
        dump(parse("notice bar")).should == "(invoke notice bar)"
      end

      it "notice(bar)" do
        dump(parse("notice bar")).should == "(invoke notice bar)"
      end

      it "foo(bar)" do
        dump(parse("foo(bar)")).should == "(invoke foo bar)"
      end

      it "foo(bar,)" do
        dump(parse("foo(bar,)")).should == "(invoke foo bar)"
      end

      it "foo(bar, fum,)" do
        dump(parse("foo(bar,fum,)")).should == "(invoke foo bar fum)"
      end

      it "notice fqdn_rand(30)" do
        dump(parse("notice fqdn_rand(30)")).should == '(invoke notice (call fqdn_rand 30))'
      end
    end

    context "in nested scopes" do
      it "if true { foo() }" do
        dump(parse("if true {foo()}")).should == "(if true\n  (then (invoke foo)))"
      end

      it "if true { notice bar}" do
        dump(parse("if true {notice bar}")).should == "(if true\n  (then (invoke notice bar)))"
      end
    end
  end

  context "When parsing calls as expressions" do
    it "$a = foo()" do
      dump(parse("$a = foo()")).should == "(= $a (call foo))"
    end

    it "$a = foo(bar)" do
      dump(parse("$a = foo()")).should == "(= $a (call foo))"
    end

    # For egrammar where a bare word can be a "statement"
    it "$a = foo bar # illegal, must have parentheses" do
      dump(parse("$a = foo bar")).should == "(block\n  (= $a foo)\n  bar\n)"
    end

    context "in nested scopes" do
      it "if true { $a = foo() }" do
        dump(parse("if true { $a = foo()}")).should == "(if true\n  (then (= $a (call foo))))"
      end

      it "if true { $a= foo(bar)}" do
        dump(parse("if true {$a = foo(bar)}")).should == "(if true\n  (then (= $a (call foo bar))))"
      end
    end
  end

  context "When parsing method calls" do
    it "$a.foo" do
      dump(parse("$a.foo")).should == "(call-method (. $a foo))"
    end

    it "$a.foo || { }" do
      dump(parse("$a.foo || { }")).should == "(call-method (. $a foo) (lambda ()))"
    end

    it "$a.foo |$x| { }" do
      dump(parse("$a.foo |$x|{ }")).should == "(call-method (. $a foo) (lambda (parameters x) ()))"
    end

    it "$a.foo |$x|{ }" do
      dump(parse("$a.foo |$x|{ $b = $x}")).should == [
        "(call-method (. $a foo) (lambda (parameters x) (block",
        "  (= $b $x)",
        ")))"
        ].join("\n")
    end
  end

  context "When parsing an illegal argument list" do
    it "raises an error if argument list is not for a call" do
      expect do
        parse("$a  = 10, 3")
      end.to raise_error(/illegal comma/)
    end

    it "raises an error if argument list is for a potential call not allowed without parentheses" do
      expect do
        parse("foo 10, 3")
      end.to raise_error(/attempt to pass argument list to the function 'foo' which cannot be called without parentheses/)
    end

    it "does no raise an error for an argument list to an allowed call" do
      expect do
        parse("notice 10, 3")
      end.to_not raise_error()
    end
  end
end
