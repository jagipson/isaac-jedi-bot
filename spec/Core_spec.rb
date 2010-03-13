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
    @bot = mock('bot')
    @bot.should_receive(:on)
    @core = Core.new(@bot)
  end
  
  it "has a join command that joins rooms"
  
  it "has a part command that parts rooms"
  
  it "has a hangup command that disconnects"
end

describe Core, "Isaac-related commands" do
  it "has a toggle_verbosity command that toggles Isaac verbosity"

end

describe Core, "plugin-related commands" do
    it "has a load_plugin command that loads plugin files"
    it "should register commands during the load process"
    it "has an unload_plugin command that unloads plugin files"
    it "should unregister commands during the unload process"
    it "should have a list_plugins command that tells the user \
        what plugins are loaded"
    it "should actually self-register its own commands when initialized"
end

describe Core, "help system" do
  it "should have useful help"
end