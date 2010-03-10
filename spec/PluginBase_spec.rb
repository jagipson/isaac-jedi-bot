require_relative '../lib/PluginBase.rb'

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
  
  before(:each) do
    # no matter what, I want a fresh class and instance for these tests
    begin
      Object.send(:remove_const, PBC)
      # Huh?  Constants aren't as constant as you thought, eh?
    rescue NameError
      # Happens when undefining a nonexistant constant, like the first time
      #the test is run
    ensure
      # Create a subclass so PluginBase doesn't raise
      class PBC < PluginBase
      end
      
      @bot = mock('bot')
      @pbc = PBC.new(@bot)
    end
  end
  
  it "should have a default_command of 'help'" do
    @pbc.should respond_to :help
  end
  
  it "should call its default_command if a missing_method is called" do
    class PBC < PluginBase
      default_command :increment
      def increment
        @count ||= 0
        @count += 1
      end
      attr_reader :count
    end
    @pbc.bogus
    @pbc.increment
    @pbc.count.should == 2
    # This means that the same method #increment ran twice; once via a call to #bogus
  end
  
  it "should raise if its default_command is missing" do
    class PBC < PluginBase
      default_command :non_existing_method_name
    end
    lambda{ @pbc.bogus }.should raise_error
  end
  
  it "should call @bot#on() for each command when registering commands" do
   # TODO: Refactor this test. This test is testing for too many things
    class PBC < PluginBase
      # commands take the form of methods defined in the class
      token :pbc1
      
      context :channel
      def uno
      end
      context :private
      def dos
      end
      context :auto
      def tres
      end
    end
    @bot.should_receive(:on).once.with(:channel, /^\s*!pbc1\s+uno\s?(.*)$/i)
    @bot.should_receive(:on).once.with(:private, /^\s*!pbc1\s+dos\s?(.*)$/i)
    @bot.should_receive(:on).once.with(:channel, /^\s*!pbc1\s+tres\s?(.*)$/i)
    @bot.should_receive(:on).once.with(:private, /^\s*!pbc1\s+tres\s?(.*)$/i)
    # Also Bot will register a default command
    @bot.should_receive(:on).once.with(:channel, /^\s*!pbc1(.*)$/i)
    @bot.should_receive(:on).once.with(:private, /^\s*!pbc1(.*)$/i)
    @pbc.method(:register_commands).call
         
  end
  
  it "should add any method defined in subclass to #commands[] unless " \
     "the method begins with underscore or the context is :helper" do
       # I don't like this test, it's too TDDy and not BDDy enough.  Help?!
       class PBC < PluginBase
         # commands take the form of methods defined in the class
         token :pbc2
         context :channel
         def uno
         end
         context :helper
         def dos
         end
         context :auto
         def _tres
         end
         def quatro
         end
       end
    @bot.should_receive(:on).with(any_args()).any_number_of_times
    @pbc.method(:register_commands).call
    
    # test for :uno and :quatro in their proper contexts
    PBC.commands.should include([:uno, :channel], [:quatro, :auto])
    
    # Factoring out just method names to here: these methods should not appear
    # in commands[], with _any_ context
    PBC.commands.map{|cp| cp[0] }.should_not include(:_tres, :dos)
  end
  
  it "should never register initialize as a command, " \
     "even if context is not :helper"  do
        class PBC < PluginBase
          # commands take the form of methods defined in the class
          token :pbc3
          
          # Let's try to expose initialize as a command...
          public
          context :auto
          def initialize
          end
        end
        
     @bot.should_receive(:on).with(any_args()).any_number_of_times
     @pbc.method(:register_commands).call

     # Factoring out just method names to here: these methods should not appear
     # in commands[], with _any_ context
     PBC.commands.map{|cp| cp[0] }.should_not include(:initialize)
   end
  
  it "should wrap each proc sent to @bot#on() in a uniform error handler" do
  # This might have said "it should not crash when there's a bug in a command"
    class PBC < PluginBase
      token :pbc4
      context :auto
      def buggy_command
        raise "Oops!  There's a runtime error in here"
      end
    end
    
    # Now call the buggy code after the wrapper is applied
    lambda { PBC.meth_wrap_proc(@pbc.method(:buggy_command)).call }.should_not raise_error
  end
  
  #it "should register both :channel and :private events when context is :auto"
  #see "should call @bot#on() for each command when registering commands"
  
  it "should call @bot#off() for each command when unregistering commands" do
   # TODO: Refactor this test. This test is testing for too many things
    class PBC < PluginBase
      # commands take the form of methods defined in the class
      token :pbc5
      
      context :channel
      def uno
      end
      context :private
      def dos
      end
      context :auto
      def tres
      end
    end
    @bot.should_receive(:on).with(any_args()).any_number_of_times
    @pbc.method(:register_commands).call
    
    @bot.should_receive(:off).once.with(:channel, /^\s*!pbc5\s+uno\s?(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!pbc5\s+dos\s?(.*)$/i)
    @bot.should_receive(:off).once.with(:channel, /^\s*!pbc5\s+tres\s?(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!pbc5\s+tres\s?(.*)$/i)
    # Also Bot will register a default command
    @bot.should_receive(:off).once.with(:channel, /^\s*!pbc5(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!pbc5(.*)$/i)
    @pbc.method(:unregister_commands).call
  end
  
  it "should respond to #config with @bot.config" do
    @bot.should_receive(:config)
    @pbc.method(:config).call
  end
  
  it "should respond to #irc with @bot.irc" do
    @bot.should_receive(:irc)
    @pbc.method(:irc).call
  end
  
  it "should respond to #nick with @bot.nick" do
    @bot.should_receive(:nick)
    @pbc.method(:nick).call
  end
  
  it "should respond to #channel with @bot.channel" do
    @bot.should_receive(:channel)
    @pbc.method(:channel).call
  end
  
  it "should respond to #message with @bot.message" do
    @bot.should_receive(:message)
    @pbc.method(:message).call
  end
  
  it "should respond to #user with @bot.user" do
    @bot.should_receive(:user)
    @pbc.method(:user).call
  end
  
  it "should respond to #host with @bot.host" do
    @bot.should_receive(:host)
    @pbc.method(:host).call
  end
  
  it "should respond to #error with @bot.error" do
    @bot.should_receive(:error)
    @pbc.method(:error).call
  end
  
  it "should respond to #args with @bot.match[0]" do
    @bot.should_receive(:match).and_return(["pattern", "matches", "array"])
    @pbc.method(:args).call
  end
  
  it "should call @bot.kick when #kick is called" do
    @bot.should_receive(:kick)
    @pbc.method(:kick).call("#channel", "user")
  end
  
  it "should call @bot.raw when #raw is called" do
    @bot.should_receive(:raw)
    @pbc.method(:raw).call("Raw server text")
  end
  
  it "should call @bot.quit when #quit is called" do
    @bot.should_receive(:quit)
    @pbc.method(:quit).call("message")
  end
  
  it "should call @bot.join when #join is called" do
    @bot.should_receive(:join)
    @pbc.method(:join).call("message")
  end
  
  it "should call @bot.part when #part is called" do
    @bot.should_receive(:part)
    @pbc.method(:part).call("message")
  end
  
  it "should call @bot.msg when #msg is called" do
    @bot.should_receive(:msg)
    @pbc.method(:msg).call("dest", "message")
  end
  
  it "should call @bot.action when #action is called" do
    @bot.should_receive(:action)
    @pbc.method(:action).call("action", "jackson")
  end
  
  it "should call @bot.topic when #topic is called" do
    @bot.should_receive(:topic)
    @pbc.method(:topic).call("room", "topic")
  end
  
  it "should call @bot.mode when #mode is called" do
    @bot.should_receive(:mode)
    @pbc.method(:mode).call("room", "mode")
  end
  
end

describe PluginBase, "automsg" do
  before(:each) do
    # no matter what, I want a fresh class and instance for these tests
    begin
      Object.send(:remove_const, PBC)
      # Huh?  Constants aren't as constant as you thought, eh?
    rescue NameError
      # Happens when undefining a nonexistant constant, like the first time
      #the test is run
    ensure
      # Create a subclass so PluginBase doesn't raise
      class PBC < PluginBase
      end
      
      @bot = mock('bot')
      @pbc = PBC.new(@bot)
    end
  end
  
  # Automsg features
  it "should call msg :channel if channel is not nil" do
    @bot.should_receive(:channel).twice.and_return("#Braincloud")
    @bot.should_receive(:msg).with("#Braincloud", "message")
    @pbc.method(:automsg).call("message")
  end
  
  it "should call msg :nick if channel is nil" do
    @bot.should_receive(:nick).and_return("bob")
    @bot.should_receive(:channel).and_return(nil)
    @bot.should_receive(:msg).with("bob", "message")
    @pbc.method(:automsg).call("message")
  end
end