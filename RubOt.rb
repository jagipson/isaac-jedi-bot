#!/usr/bin/env ruby
# encoding: utf-8

# includes for Ruby 1.8.x
require 'lib/R1.8-Kernel_extension' if defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.8\.*/

$system_root = __FILE__.sub(File.basename(__FILE__),"")
require 'rubygems'
require 'isaac'
require_relative 'lib/ConfigurationModule'
require_relative 'lib/OverridesSTDIO_module'
include OverridesSTDIO

BOT_CONFIG = configuration_from_file

configure do |c|
  c.server    = BOT_CONFIG[:connection_parameters][:server] || exit
  c.port      = BOT_CONFIG[:connection_parameters][:port] || 6667
  c.ssl       = BOT_CONFIG[:connection_parameters][:ssl]
  c.nick      = BOT_CONFIG[:bot_nick]
  c.realname  = BOT_CONFIG[:connection_parameters][:realname] || "John Adams"
  c.version   = Time.now.to_s
  c.verbose   = false
end

on :connect do
  if (BOT_CONFIG[:nickserv_secret] and BOT_CONFIG[:nickserv_secret] != "") then
    msg "NickServ", "IDENTIFY #{BOT_CONFIG[:bot_nick]} #{BOT_CONFIG[:nickserv_secret]}" 
  end
  msg BOT_CONFIG[:owner_nick], "New RuBot instance connected as #{BOT_CONFIG[:bot_nick]}"
  warn "Connected."
end

require_relative 'lib/Core'

# Run this file
# ruby RubOt.rb

# Look at Banter.rb as an example plugin
# Load the plugin using /msg <bot_nick> !do load_plugin Banter.rb
#
# Then invoke fortune like this:
# !fortune
