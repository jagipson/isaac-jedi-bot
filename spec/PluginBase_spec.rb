require 'lib/PluginBase.rb'


describe PluginBase, "abstract class" do
  
  it "should raise if you instantiate it directly" do
    lambda { pb = PluginBase.new }.should raise_exception(RuntimeError, "warning: PluginBase was instantiated directly")
  end
end

describe PluginBase, "bare subclass" do
 
  before (:all) do
    # Create a subclass so PluginBase doesn't raise
    class PBC < PluginBase
    end
  end
  
  before (:each) do
    pbc = PBC.new
  end
  
  # Pertaining to its behaviour as a class (default behaviour):
  
  it "should provide a default description"
  
  it "should not provide a default token"
  
  it "should raise if token is nil"
  
  it "should raise if token is not unique"
  
  it "should raise if token !~/^[A-Za-z]+[A-Za-z0-9]*$/i"
  
  it "should have a default_command of 'help'"
  
  it "should call its default_command if a missing_method is called"
  
  it "should raise if its default_command is missing"
  
  it "should have a default_command_context of :auto"
  
  it "should have a default context of :auto"
  
  it "should return an array of #commands"
  
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

  it "should provide a default help command"
  
end

describe PluginBase, "automsg"

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
  
  "should "
  
end