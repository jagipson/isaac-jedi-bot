require 'lib/R1.8-Kernel_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/
require_relative '../lib/PluginBase'

describe PluginBase, "abstract class" do
  
  it "should raise if you instantiate it directly" do
    lambda { pb = PluginBase.new }.should raise_exception(RuntimeError, "warning: PluginBase was instantiated directly")
  end
end

describe PluginBase, "bare subclass, class methods and properties" do

  # Create a subclass so PluginBase doesn't raise
  class PBC < PluginBase
  end
  
  # These are describing class methods
  # Pertaining to its behaviour as a class (default behaviour):
  it "should provide a default description" do
    PBC.desc.should be_a(String)
    class PBC < PluginBase
      description         "new description"
    end
    PBC.desc.should match /new description/
  end
  
  it "should provide a default token == class name" do
    PBC.get_token.should be PBC.name.downcase.to_sym
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
    PBC.get_default_command_context.should be :auto
  end
  
  it "should allow setting of default_command_context" do
    PBC.default_command_context :private
    PBC.get_default_command_context.should be :private
  end  
  
  it "should have a default context of :auto" do
    # Context isn't set until the first method is added, so we must add 
    # a dummy method on PBC (or functionally, we should decide on a default
    # method on PBC, perhaps a default help
    lambda {
      class PBC < PluginBase
        def useless_method
          nil
        end
        # TODO where did this instance variable come from?
        throw @context 
      end
    }.should throw_symbol :auto
  end
  
  it "should return an array of #commands" do
    PBC.commands.should == [[:useless_method, :auto]]
  end
  
end


