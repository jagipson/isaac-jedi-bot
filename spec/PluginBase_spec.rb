require 'lib/R1.8-Kernel_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/
require 'lib/R1.8-Array_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/
require_relative '../lib/PluginBase'

describe PluginBase, "class instances and operations" do
  
  before(:each) do
    # no matter what, I want a fresh class and instance for these tests
    begin
      Object.send(:remove_const, :PBC)
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
    # Test MUST call the default_command, which isn't defined
    lambda{ @pbc.non_existing_method_name }.should raise_error
  end
  
  it "should call @bot#on() for each command when registering commands" do
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
  # That's great, but what if the user specified a default_command_context?
  
  it "should use the user-supplied default_command_context" do
    class PBC < PluginBase
      token :pbc1a
      default_command_context   :private
    end
    @bot.should_not_receive(:on).with(:channel, /^\s*!pbc1a(.*)$/i)
    @bot.should_receive(:on).once.with(:private, /^\s*!pbc1a(.*)$/i)
    # It should also return the proper channel to associate the command with.
    # Or should it?  a TODO now requests that we decide what register_commands
    # should return, and then we need to rewrite this next statement
    @pbc.method(:register_commands).call.should == [:private]
  end

  it "should add any method defined in subclass to #commands[] unless\
 the method begins with underscore or the context is :helper" do
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

    @bot.should_receive(:on).with(any_args()).exactly(2).times
    @pbc.method(:register_commands).call.should  == [:channel, :private]

    # Factoring out just method names to here: these methods should not appear
    # in commands[], with _any_ context
    PBC.commands.map{ |cp| cp[0] }.should_not include(:initialize)
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
    # TODO continue from here.
    @bot.should_receive(:on).with(any_args()).exactly(6).times
    @pbc.method(:register_commands).call

    @bot.should_receive(:off).once.with(:channel, /^\s*!pbc5\s+uno\s?(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!pbc5\s+dos\s?(.*)$/i)
    @bot.should_receive(:off).once.with(:channel, /^\s*!pbc5\s+tres\s?(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!pbc5\s+tres\s?(.*)$/i)
    # Also Bot will register a default command
    @bot.should_receive(:off).once.with(:channel, /^\s*!pbc5(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!pbc5(.*)$/i)
    #We are making sure that the methods are unregistered
    # Need to determine what unregister_commands should return and test for that
    @pbc.method(:unregister_commands).call.methods == [] 
  end

  it "should run off with the user-supplied default_command_context" do
    class PBC < PluginBase
      token :pbc5a
      default_command_context   :private
    end
    @bot.should_not_receive(:off).with(:channel, /^\s*!pbc5a(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!pbc5a(.*)$/i)
    # Need to determine what unregister_commands should return and test for that
    @pbc.method(:unregister_commands).call.methods == [] 
  end

  test_receives = [:config, :irc, :nick, :channel, :message, :user, :host, :error]

  test_receives.each do |symbol|
    it "should respond to ##{symbol.to_s} with @bot.#{symbol.to_s}" do
      @bot.should_receive(symbol)
      @pbc.method(symbol).call
    end
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

  test_receives_with_message = [:quit, :join, :part]
  test_receives_with_message.each do |symbol|
    it "should call @bot.#{symbol.to_s} when #{symbol.to_s} is called" do
      @bot.should_receive(symbol)
      @pbc.method(symbol).call("message")
    end
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

  it "should return self when initialized" do
    @pbc = PBC.new(@bot)
    @pbc.should be_a_kind_of(PluginBase)
  end

  it "should show publicly available commands in public (default help)" do
    class PBC < PluginBase
      # commands take the form of methods defined in the class
      token :pbc6
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
    @bot.should_receive(:on).with(any_args()).exactly(6).times
    @pbc.method(:register_commands).call
    @bot.should_receive(:channel).exactly(3).times.and_return("#braincloud")
    @bot.should_receive(:msg).with("#braincloud", "!pbc6 (uno|tres)")
    @pbc.help
  end

  it "should show privately available commands in priv (default help)" do
    class PBC < PluginBase
      # commands take the form of methods defined in the class
      token :pbc7
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
    @bot.should_receive(:on).with(any_args()).exactly(6).times
    @pbc.method(:register_commands).call
    @bot.should_receive(:channel).exactly(2).times.and_return(nil)
    @bot.should_receive(:nick).exactly(1).times.and_return("bob")
    @bot.should_receive(:msg).with("bob", "!pbc7 (dos|tres)").and_return(nil)
    @pbc.help.should be nil
  end
  
  after(:all) do
    # perform cleanup or other tests might fail
    Object.send(:remove_const, :PBC) if RUBY_VERSION =~ /1\.8\.\d/
      # Object.send(:remove_const, :PBC) if RUBY_VERSION =~ /1\.9\.\d/
      class PBC < PluginBase
      end
  end
end

