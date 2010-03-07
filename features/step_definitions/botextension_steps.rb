require 'isaac'
require 'lib/PluginBase.rb'
require 'lib/ConfigurationModule.rb'

Given /^an extended bot$/ do
  $bot = Isaac::Bot.new
  $bot.extend BotExtensions
end

When /^it has a "([^\"]*)" "([^\"]*)" event$/ do |arg1, arg2|
  $bot.on arg2.to_sym, /(#{arg1})/  do |a1|
    throw a1.to_sym
  end
end
  
When /^I remove the "([^\"]*)" "([^\"]*)" event$/ do |arg1, arg2|
  $bot.off(arg2.to_sym, /(#{arg1})/)
end

Then /^it responds to the "([^\"]*)" "([^\"]*)" event$/ do |arg1, arg2|
  catch arg1.to_sym do
    # Make a raw IRC message for the test
    n = Isaac::Message.new(":Nick!Host@no.where PRIVMSG myChannel: Hello there, #{arg1}; nice day?")
    $bot.dispatch arg2.to_sym, n
    raise "$bot did not respond to #{arg1} event #{arg2}" 
  end
end

Then /^it does not respond to the "([^\"]*)" "([^\"]*)" event$/ do |arg1, arg2|
  # and uncaught throw will occur if $bot responds
  # Make a raw IRC message for the test
  n = Isaac::Message.new(":Nick!Host@no.where PRIVMSG myChannel: Hello there, #{arg1}; nice day?")
  $bot.dispatch arg2.to_sym, n
end

Then /^no exception should be thrown if I remove a non\-existent event$/ do
  When "I remove the \"nonexistant\" \"channel\" event"
end
