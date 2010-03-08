require 'lib/ConfigurationModule'

Given /^a non\-existent config file name$/ do
  $temp_file = "Cucumber_config_test.#{(10000 * rand).to_i.to_s}.yaml"
end

When /^loading the configuration$/ do
  @load_exception = nil
  begin
    @test_default_config = configuration_from_file($temp_file)
  rescue Exception => @load_exception
  end
end

Then /^create a default configuration file and exit$/ do
  # First test for a SystemExit Exception, an reraise if not an exit
  raise @load_exception unless @load_exception.kind_of?(SystemExit)
  # check default config by reloading the config file
  configuration_from_file($temp_file)
end  

Given /^a request to load an existing config$/ do 
  unless File.exists?($temp_file) then
    raise "Testing Error, expected to find existing temporary file #{$temp_file}"
  end
end


Then /^I should have a populated global configuration hash$/ do
  # First check for no load exception
  raise @load_exception if @load_exception
  
  # The default config should minimally contain these items, even if not 
  # applicable, to help the user know what settings can be edited in the file
  # Top level hash
  [:bot_nick, 
   :owner_nick, 
   :connection_parameters, 
   :nickserv_secret].each do |key|
     unless @test_default_config.has_key? key
       raise "Missing Root Configuration Key #{key.to_s}" 
     end
   end
   
   # Test for second-level connection parameters
   [:server, 
    :port, 
    :ssl, 
    :realname,
    :verbose].each do |key|
      unless @test_default_config[:connection_parameters].has_key? key
        raise "Missing Connection Parameter Configuration Key #{key.to_s}" 
      end
    end
    # All the keys are present
end

Given /^a corrupt config file$/ do
  # Scramble the config file
  f = File.new($temp_file)
  lines = f.readlines
  f.close
  
  lines.reverse!
  File.open($temp_file, "w") do |scrambled|
    scrambled.write lines.join("\n")
  end
end

Then /^it should fail$/ do
  raise "Should have failed load due to corrupt file" unless @load_exception
end
