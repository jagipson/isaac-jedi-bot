require 'lib/R1.8-Kernel_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/
require 'lib/R1.8-Array_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/
begin
  require_relative '../lib/Core'
rescue NoMethodError
  # Happens because non-Class code exists in Core.rb which when normally
  # called in the context of the program works, but because of how we
  # load it here, it fails
end

describe Core, "identity" do
  before(:each) do
    # no matter what, I want a fresh class and instance for these tests
    begin
      Object.send(:remove_const, :Core)
      # Huh?  Constants aren't as constant as you thought, eh?
    rescue NameError
      # Happens when undefining a nonexistant constant, like the first time
      #the test is run
    ensure
      @bot = mock('bot')
      @core = Core.new(@bot)
    end
  end

end

