# encoding: utf-8

require 'lib/R1.8-Kernel_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/
require 'lib/R1.8-Array_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/
begin
  require_relative '../lib/Core'
rescue NoMethodError
  # Happens because non-Class code exists in Core.rb which when normally
  # called in the context of the program works, but because of how we
  # load it here, it fails
end

describe Core, "irc-related commands" do
  before(:each) do
    Core::BOT_CONFIG = {}
    Core::BOT_CONFIG[:owner_nick] = "bob"
    @bot = mock('bot')
    @bot.should_receive(:on).exactly(11).times
    @core = Core.new(@bot)
  end
  
  it "has a join command that joins a room (bot owner only)" do
    @bot.should_receive(:match).and_return(["#braincloud"])
    @bot.should_receive(:nick).and_return('bob')
    @bot.should_receive(:join).once.with("#braincloud")
    
    @core.join
  end
  
  it "join command also joins a list of rooms (bot owner only)" do
    @bot.should_receive(:match).and_return(["#roomA #roomB #roomC"])
    @bot.should_receive(:nick).exactly(3).times.and_return('bob')
    @bot.should_receive(:join).once.with("#roomA")
    @bot.should_receive(:join).once.with("#roomB")
    @bot.should_receive(:join).once.with("#roomC")
    
    @core.join
  end
  
  it "has a join command that ignores non bot owner" do
    @bot.should_receive(:match).and_return(["#braincloud"])
    @bot.should_receive(:nick).and_return('dan')
    @bot.should_not_receive(:join)
    
    @core.join
  end
  
  
  it "has a part command that parts a room (bot owner only)" do
    @bot.should_receive(:match).and_return(["#braincloud"])
    @bot.should_receive(:nick).and_return('bob')
    @bot.should_receive(:part).once.with("#braincloud")
    
    @core.part
  end
  
  it "part command also parts a list of rooms (bot owner only)" do
    @bot.should_receive(:match).and_return(["#roomA #roomB #roomC"])
    @bot.should_receive(:nick).exactly(3).times.and_return('bob')
    @bot.should_receive(:part).once.with("#roomA")
    @bot.should_receive(:part).once.with("#roomB")
    @bot.should_receive(:part).once.with("#roomC")
    
    @core.part
  end
  
  it "has a part command that ignores non bot owner" do
    @bot.should_receive(:match).and_return(["#braincloud"])
    @bot.should_receive(:nick).and_return('dan')
    @bot.should_not_receive(:part)
    
    @core.part
  end
  
  it "has a hangup command that disconnects (bot owner only)" do
    @bot.should_receive(:nick).and_return('bob')
    @bot.should_receive(:quit)
    
    @core.hangup
  end
  
  it "hangup command that ignores non bot owner" do
    @bot.should_receive(:nick).and_return('dan')
    @bot.should_not_receive(:quit)
    
    @core.hangup
  end
end

describe Core, "Isaac-related commands" do
  before(:each) do
    require 'rubygems'
    require 'isaac/bot'
    Core::BOT_CONFIG = {}
    Core::BOT_CONFIG[:owner_nick] = "bob"
    @config = Isaac::Config.new
    @bot = mock('bot')
    @bot.should_receive(:on).exactly(11).times
    @core = Core.new(@bot)
  end
  
  it "has a toggle_verbosity command that toggles Isaac verbosity \
      (owner only)" do
    @bot.should_receive(:nick).twice.and_return('bob')
    @bot.should_receive(:configure).twice.and_yield(@config)
    @config[:verbose].should_not == true
    @core.toggle_verbosity
    @config[:verbose].should == true
    @core.toggle_verbosity
    @config[:verbose].should == false
  end

end

describe Core, "load_plugin command" do
    before(:each) do
      # following line from RubOt.rb
      $system_root = __FILE__.sub(File.basename(__FILE__),"") + ".."
      
      @plug = mock('plugin')
      @bot = mock('bot')
      @bot.should_receive(:on).exactly(11).times
      @core = Core.new(@bot)
    end
    
    it "should tell owner each plugin listed that doesn't exist" do
      @bot.should_receive(:nick).exactly(3).times.and_return("bob")
      @bot.should_receive(:msg).once.with("bob", /Unable to find plugin .*first.rb;.*/)
      @bot.should_receive(:msg).once.with("bob", /Unable to find plugin .*second.rb;.*/)
      @bot.should_receive(:msg).once.with("bob", /Unable to find plugin .*third.rb;.*/)
      @bot.should_receive(:match).and_return(["first second third"])
      @core.load_plugin
    end
    
    it "should tell owner when a plugin load attempt goes awry" do
      @bot.should_receive(:nick).and_return("bob")
      @bot.should_receive(:msg).once.with("bob", /Unable to load plugin .*trash.*/)
      
      # Make trash file to simulate plugin file with syntax error
      # The trash file incorporates the pid ($$) of the running process to 
      # prevent a race condition that would otherwise be created if multiple 
      # autotests were being run simultaneously 
      File.open($system_root + "/plugins/trash.#{$$}.rb", "w") do |fh|
        fh.puts "this is invalid ruby code"
      end
      
      @bot.should_receive(:match).and_return(["trash.#{$$}"])
      @core.load_plugin
      
      # take out the trash
      File.delete($system_root + "/plugins/trash.#{$$}.rb")
    end
     
    it "should register commands during the load process" do
      @bot.should_receive(:nick).and_return("bob")
      @bot.should_receive(:msg).once.with("bob", /.*Trash#{$$} loaded.*/)
      
      # Make trash file to simulate plugin file with syntax error
      # The trash file incorporates the pid ($$) of the running process to 
      # prevent a race condition that would otherwise be created if multiple 
      # autotests were being run simultaneously 
      File.open($system_root + "/plugins/Trash#{$$}.rb", "w") do |fh|
        fh.puts "class Trash#{$$} < PluginBase"
        fh.puts "  def test"
        fh.puts "  end"
        fh.puts "end"
      end
      @bot.should_receive(:on).exactly(4).times
      @bot.should_receive(:match).and_return(["Trash#{$$}"])
      @core.load_plugin
      
      # take out the trash
      File.delete($system_root + "/plugins/Trash#{$$}.rb")
    end
end

describe Core, "unload_plugin command" do
  before(:all) do #setup environment with stub plugin
    # following line from RubOt.rb
    $system_root = __FILE__.sub(File.basename(__FILE__),"") + ".."
    
    @plug = mock('plugin')
    @bot = mock('bot')
    @bot.should_receive(:on).exactly(14).times
    @core = Core.new(@bot)
    @bot.should_receive(:nick).and_return("bob")
    @bot.should_receive(:msg).once.with("bob", /.*Trash#{$$} loaded.*/)
    
    # Make trash file to simulate plugin file with syntax error
    # The trash file incorporates the pid ($$) of the running process to 
    # prevent a race condition that would otherwise be created if multiple 
    # autotests were being run simultaneously 
    File.open($system_root + "/plugins/Trash#{$$}.rb", "w") do |fh|
      fh.puts "class Trash#{$$} < PluginBase"
      fh.puts "  def test"
      fh.puts "  end"
      fh.puts "end"
    end
    @bot.should_receive(:on).exactly(3).times
    @bot.should_receive(:match).and_return(["Trash#{$$}"])
    @core.load_plugin
  end
        
  it "has an unload_plugin command that unloads plugin files and \
      unregisters commands via #off() " do
    # Since Core is already loaded for testing, we will unload it (convenience)
    @bot.should_receive(:nick).and_return("bob")
    @bot.should_receive(:match).and_return(["Trash#{$$}"])
    @bot.should_receive(:off).twice.with(:channel, /^\s*!trash#{$$}\s+test\s?(.*)$/i)
    @bot.should_receive(:off).twice.with(:private, /^\s*!trash#{$$}\s+test\s?(.*)$/i)
    @bot.should_receive(:off).once.with(:channel, /^\s*!trash#{$$}(.*)$/i)
    @bot.should_receive(:off).once.with(:private, /^\s*!trash#{$$}(.*)$/i)
    @bot.should_receive(:msg).once.with("bob", /Trash#{$$} unloaded./)
    @core.unload_plugin
  end
  
  after(:all) do
    File.delete($system_root + "/plugins/Trash#{$$}.rb")
  end
end

describe Core, "plugin_list" do  
  before(:each) do
    @bot = mock('bot')
    @bot.should_receive(:on).exactly(11).times
    @core = Core.new(@bot)
  end
  it "should have a list_plugins command that tells the user \
      what plugins are loaded" do
    # These are the calculated responses
    @bot.should_receive(:nick).exactly(8).times
    @bot.should_receive(:msg).exactly(8).times
    @bot.should_receive(:on).exactly(3).times
    @core.list_plugins
    @core.load_plugin "TestPlug"
    @core.list_plugins
  end
      
  it "should actually self-register its own commands when initialized" do
    @bot.should_receive(:nick).exactly(3).times.and_return("bob")
    @bot.should_receive(:msg).once.with("bob", /loaded plugins in order of appearance:.*/)
    @bot.should_receive(:msg).once.with("bob", /Token.*Name.*Description.*/)
    @bot.should_receive(:msg).once.with("bob", /!do.Core.*Core plugin for administrative tasks.*/)
    @core.list_plugins
  end
end

describe Core, "help system" do
  before(:each) do
    @bot = mock('bot')
    @bot.should_receive(:on).exactly(11).times
    @core = Core.new(@bot)
  end
  it "should have useful help" do
    # Whether the help us useful us purely subjective... Let's just make
    # sure the is *some* help
    @bot.should_receive(:match).any_number_of_times.and_return([""])
    @bot.should_receive(:nick).any_number_of_times.and_return("bob")
    @bot.should_receive(:msg).at_least(2).times
    @core.should_respond_to(:help)
  end
  
  it "should provide specific help for each command except help" do
    @core.class.commands.delete([:help, :auto])
    @core.class.commands.each do |cmnd|
      @bot.should_receive(:nick).any_number_of_times.and_return("bob")
      @bot.should_receive(:match).and_return([ cmnd[0].to_s ])
      @bot.should_receive(:msg).once.with("bob", /!do #{cmnd[0].to_s}/)
      @bot.should_receive(:msg).any_number_of_times.with("bob", /^((?!!do).)*$/)
      @core.help
    end
  end
  
end