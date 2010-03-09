require 'lib/PluginBase.rb'


describe PluginBase, "abstract class" do
  
  it "should raise if you instantiate it directly" do
    lambda { pb = PluginBase.new }.should raise_exception(RuntimeError, "warning: PluginBase was instantiated directly")
  end
end

describe PluginBase, "bare subclass, class methods and properties" do

  # Create a subclass so PluginBase doesn't raise
  class PBC < PluginBase
  end
  
  # Pertaining to its behaviour as a class (default behaviour):
  it "should provide a default description" do
    PBC.desc.should match /PBC is indescribable!/
    class PBC < PluginBase
      description         "new description"
    end
    PBC.desc.should match /new description/
  end
  
  it "should not provide a default token" do
    PBC.get_token.should be_nil
  end
  
  it "should raise if setting a token that's nil" do
    lambda { PBC.token nil }.should raise_error
  end
  
  it "should raise if token is not unique" do
    class Other < PluginBase
      token :notunique
    end
    lambda { PBC.token :notunique }.should raise_error
  end
  
  it "should raise if token !~/^[A-Za-z]+[A-Za-z0-9]*$/i" do
    lambda { PBC.token :not_valid }.should raise_error
  end
    
  it "should have a default_command_context of :auto" do
    PBC.get_default_command_context.should == :auto
  end
  
  
  it "should have a default context of :auto" do
    # Context isn't set until the first method is added, so we must add 
    # a dummy method on PBC 
    lambda {
      class PBC < PluginBase
        def useless_method
          nil
        end
        throw @context
      end
    }.should throw_symbol :auto
  end
  
  it "should return an array of #commands" do
    PBC.commands.should be_kind_of(Array)
  end
  
end

describe PluginBase, "class instances and operations" do

  it "should have a default_command of 'help'"
  
  it "should call its default_command if a missing_method is called"
  
  it "should raise if its default_command is missing"
  
  it "should call @bot#on() for each command when registering commands"
  
  it "should add any method defined in subclass to #commands[] unless the method begins with underscore or the context is :helper"
  
  it "should never register initialize as a command, even if context is not :helper"
  
  it "should wrap each proc sent to @bot#on() in a uniform error handler"
  
  it "should register both :channel and :private events when context is :auto"
  
  it "should call @bot#off() for each command when unregistering commands"
  
  it "should respond to #config with @bot.config"
  
  it "should respond to #irc with @bot.irc"
  
  it "should respond to #nick with @bot.nick"
  
  it "should respond to #channel with @bot.channel"
  
  it "should respond to #message with @bot.message"
  
  it "should respond to #user with @bot.user"
  
  it "should respond to #host with @bot.host"
  
  it "should respond to #error with @bot.error"
  
  it "should respond to #args with @bot.match[0]"
  
  it "should call @bot.kick when #kick is called"
  
  it "should call @bot.raw when #raw is called"
  
  it "should call @bot.quit when #quit is called"
  
  it "should call @bot.join when #join is called"
  
  it "should call @bot.part when #part is called"
  
  it "should call @bot.msg when #msg is called"
  
  it "should call @bot.action when #action is called"
  
  it "should call @bot.topic when #topic is called"
  
  it "should call @bot.mode when #mode is called"
  
  
end

describe PluginBase, "automsg" do

  # Automsg feature
  
  it "should call msg :channel if channel is not nil"
  
  it "should call msg :nick if channel is nil"
  
end

describe PluginBase, "customized subclass" do
  
    it "should remember your description"
    
    
end

describe PluginBase, "bare subclass in chat" do
  
  before (:all) do
    # Create a subclass so PluginBase doesn't raise
    class PBC < PluginBase
    end
  end
  
  before (:each) do
    pbc = PBC.new
  end
  
  # Pertaining to its behaviour in IRC
  
  
end