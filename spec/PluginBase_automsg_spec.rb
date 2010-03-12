require_relative '../lib/PluginBase'

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
