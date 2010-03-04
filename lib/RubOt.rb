#!/usr/bin/env ruby
# encoding: utf-8

# Guarantee Ruby 1.9.x
exit(1) unless defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.9\.*/

require 'isaac'
require 'RubOtConfigurationModule'

$bot_config = configuration_from_file

configure do |c|
  c.server    = $bot_config[:connection_parameters][:server] || exit
  c.port      = $bot_config[:connection_parameters][:port] || 6667
  c.ssl       = $bot_config[:connection_parameters][:ssl]
  c.nick      = $bot_config[:bot_nick]
  c.realname  = $bot_config[:connection_parameters][:realname] || "John Adams"
  c.version   = Time.now.to_s
  c.verbose   = false
end

on :connect do
  if ($bot_config[:nickserv_secret] and $bot_config[:nickserv_secret] != "") then
    msg "NickServ", "IDENTIFY #{$bot_config[:bot_nick]} #{$bot_config[:nickserv_secret]}" 
  end
  puts "Connected."
end

require 'RubOtCore'

# Run this file
# ruby RubOt.rb

# Look at Banter.rb as an example plugin
# Load the plugin using /msg <bot_nick> !do load_plugin Banter.rb
#
# Then invoke fortune like this:
# !fortune
