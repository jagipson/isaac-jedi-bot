require 'spec/helper'
require_relative '../lib/PluginBase.rb'
require_relative '../plugins/Greets.rb'

describe Greets, "as a proper plugin" do
  
  it "should be the same name as the file that contains it" do
    $LOADED_FEATURES.map{|f|  File.basename(f, ".rb") }.should include Greets.name
  end
  
  it "should have a description" do
    Greets.desc.should be_a_kind_of String
    Greets.desc.size.should be > 0
  end
  
  it "should use greet for it's token" do
    Greets.get_token.should == :greet
  end
end

describe Greets, "as a well-written plugin" do
  before(:each) do
    @instance = Greets.new
  end
  it "should override PluginBase's built-in help" do
    # Note: there are much better ways of testing this in Ruby 1.9.  This test
    # was written to work in both, at least both MRI 1.8 & 1.9
    @instance.method(:help).inspect.should_not match /PluginBase/
  end
end

describe Greets, "provided command space" do
  before(:each) do
    @bot = mock("Isaac::Bot")
    @instance = Greets.new(@bot)
  end
  it "should respond only to help, hi, and hello in public and private" do
    Greets.commands.select{ |pair| pair[1] == :auto }.map{|pair| pair[0]}.should == [:help, :hi, :hello]
  end

  it "should respond to special only in private" do
    Greets.commands.select{ |pair| pair[1] == :private }.map{|pair| pair[0]}.should == [:special]
  end
end

describe Greets, "command actions" do
  before(:each) do
    @bot = mock("Isaac::Bot")
    @instance = Greets.new(@bot)
  end
  it "should tell you about Additional features when you run help" do
    @bot.should_receive(:channel).any_number_of_times.and_return("#braincloud")
    @bot.should_receive(:msg).once.with("#braincloud", /additional features available/i)
    @bot.should_receive(:msg).once.with("#braincloud", "!greet (help|hi|hello)")
    @instance.help
  end
  
  it "should say hi back, if you said hi" do
    @bot.should_receive(:channel).any_number_of_times.and_return("#braincloud")
    @bot.should_receive(:nick).any_number_of_times.and_return("bob")
    @bot.should_receive(:msg).once.with("#braincloud", "bob said hi!")
    @instance.hi
  end
  
  it "should say hello back, if you said hello" do
    @bot.should_receive(:channel).any_number_of_times.and_return("#braincloud")
    @bot.should_receive(:nick).any_number_of_times.and_return("bob")
    @bot.should_receive(:msg).once.with("#braincloud", "Hello, bob")
    @instance.hello
  end
  
  it "should say something special" do
    @bot.should_receive(:channel).any_number_of_times.and_return("#braincloud")
    @bot.should_receive(:nick).any_number_of_times.and_return("bob")
    @bot.should_receive(:msg).once.with("bob", /short bus/i)
    @instance.special
  end
end