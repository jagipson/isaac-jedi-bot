#!/usr/bin/env ruby
# encoding: utf-8

# Guarantee Ruby 1.9.x
# I chose RUBY_VERSION here, because RUBY_REVISION doesn't seem to be defined in
# some builds. -jg
exit(1) unless defined?(RUBY_VERSION) and RUBY_VERSION =~ /1\.9\.*/

# require libraries required in core
require 'isaac'
require 'yaml'
# TODO: Refactor,relocate 'wx_alert' require to wx_alert presentation layer code.
require 'lib/wx_alert.rb'
# TODO: Refactor,relocate 'uri' require to wx_alert presentation layer code.
require 'uri'

# Read the configuration file
def read_configuration(config_root, config_file=DEFAULT_CONF)
  
  fatal_errors_occured = false
  
  if (File.exist?(config_file)) then
    config_root = YAML.load_file(config_file)
    # ensure that yaml represented a hash
    if (not config_root.kind_of?(Hash)) then
      fatal_errors_occured = true
      warn "Fatal: Corrupt configuration (#{config_file})"
      exit #immediately, really.  nothing else to examine
    end
    # Testing cruft:
    #puts "Did read config:\n#{config_root.inspect}"
  end  
  
  # Make sure initial nick is set
  if (not config_root[:bot_nick]) then
    config_root[:bot_nick] = "UnnamedBot_#{(rand * 10000).to_i}"
    warn "No setting for $bot_config[:bot_nick].  Using #{config_root[:bot_nick]}"
  end
  
  # Make sure owner nick is set
  if (not config_root[:owner_nick]) then
    config_root[:owner_nick] = ENV["USER"]
    warn "No setting for $bot_config[:bot_nick].  Using #{config_root[:owner_nick]}"
  end
   
  # Make sure required connection settings are set
  # connection parameters is a hash
  config_root[:connection_parameters] ||= {}
  if not config_root[:connection_parameters].kind_of?(Hash) then
    fatal_errors_occured = true
    warn "Fatal: Corrupt configuration (connection_parameters)"
  end
  %w(server port ssl realname verbose).each do |setting|
    if (not config_root[:connection_parameters][setting.to_sym]) then
      config_root[:connection_parameters][setting.to_sym] = "#{setting}"
      warn "No #{setting} setting for $bot_config[:bot_nick]. Please check #{config_file}"
      fatal_errors_occured = true
    end
  end
  
  config_root[:nickserv_secret] ||= ""
  
  write_configuration(config_root, config_file)
  exit if fatal_errors_occured
end

def write_configuration(config_root, config_file=DEFAULT_CONF)
  File.open(config_file, "w") { |f| YAML.dump(config_root, f) }
end

# For now, the << operator has been defined on Hash to insert an array of 2
# elements into the hash object.  This was laziness, because I had allready coded
# using the << operator everywhere and thought rather than recoding, I'd just
# implement the operator in the Hash class.  The whole strategy should be deprecated
# as soon as we create a plugin object that handles user help.  The only hash
# object that uses this is the one used for the current help system

# Extend Hash, make function alias
class Hash
  def <<(twoElemArray)
    if (twoElemArray.kind_of?(Array) and twoElemArray.size == 2) then
      self[twoElemArray[0]] = twoElemArray[1]
    else
      raise ArgumentError
    end
  end
end


$SAFE = 1

# Define config structure for saving as YAML as a HASH
puts "init bot_config"
$bot_config = {}
DEFAULT_CONF="jedbotcnf.yaml"
puts "load bot_config"
read_configuration($bot_config)
p $bot_config

configure do |c|
  p $bot_config
  c.server    = $bot_config[:connection_parameters][:server] || exit
  c.port      = $bot_config[:connection_parameters][:port] || 6667
  c.ssl       = $bot_config[:connection_parameters][:ssl]
  c.nick      = $bot_config[:bot_nick]
  c.realname  = $bot_config[:connection_parameters][:realname] || "John Adams"
  c.version   = Time.now.to_s
  c.verbose   = false
end

##### CORE BOT FUNCTIONALITY #####
$help = {} # Hash for help.
$secret_help = {}
on :connect do
  # if config_root[:nickserv_secret] is defined and non-empty, authenticate
  if (config_root[:nickserv_secret] and config_root[:nickserv_secret] != "") then
    msg "NickServ", "IDENTIFY #{$bot_config[:bot_nick]} #{$bot_config[:nickserv_secret]}" 
  end
  puts "Connected."

#  TODO: These don't belong here, they are initializers, nothing to do with connection
  connect_owner_controls
  connect_wx_alerts
  connect_dictionary
end
#####

##### OWNER CONTROLS #####


# Recall the room shoud should be in
def connect_owner_controls
  @sticky_rooms ||= []
  if (File.exist?("isaac-rooms.yaml")) then
    @sticky_rooms = YAML.load_file("isaac-rooms.yaml")
    @sticky_rooms.each { |room| join room }
  end
end

# Join as I tell you
help_prefix = "(Owner Only/private)"
$secret_help << [:join, "#{help_prefix} join <#room1> [#room2] [#room3]... :: Join IRC Room(s)"]
on :private, /\s*join\s+(.*)$/i do |roomlist|
  roomlist.split(" ").each do |room|
    if (nick =~ /^#{$bot_config[:owner_nick]}$/i) and (room =~ /#[\w-]+/)
      join room
      @sticky_rooms << room.upcase.to_sym
      @sticky_rooms.uniq!
      puts "Joining #{room} already in #{@sticky_rooms}"
    end
  end
end

# Part when I say
$secret_help << [:part, "#{help_prefix} join <#room1> [#room2] [#room3]... :: Leaves IRC Room(s)"]
on :private, /\s*part\s+(.*)$/i do |roomlist|
    roomlist.split(" ").each do |room|
    if (nick =~ /^#{$bot_config[:owner_nick]}$/i) and (room =~ /#[\w-]+/)
      part room
      @sticky_rooms.delete(room.upcase.to_sym)
      puts "Leaving #{room}, remaining in #{@sticky_rooms}"
    end
  end
end

helpers do
  # Save memory to disk
  def sync
    File.open("isaac-rooms.yaml", "w") { |f| YAML.dump(@sticky_rooms, f) }
    File.open("isaac-dictionaries.yaml", "w") { |f| YAML.dump(@dictionaries, f) }
    msg nick, "sunk"
  end
end

# sync when I say
$secret_help << [:sync, "#{help_prefix} sync :: persist joined room list to disk - \n\twill be rejoined when bot is launched"]
on :private, /sync/i do 
  if (nick =~ /^#{$bot_config[:owner_nick]}$/i)
    sync
  end
end

# Die when I say
$secret_help << [:hangup, "#{help_prefix} :: perform sync, then disconnect"]
on :private, /hangup/i do 
  if (nick =~ /^#{$bot_config[:owner_nick]}$/i)
    sync
    quit("Owner demanded hangup")
  end
end

# toggle verbosity
$secret_help << [:"toggle verbosity", "#{help_prefix} :: toggle verbosity"]
on :private, /toggle verbosity/i do 
  if (nick =~ /^#{$bot_config[:owner_nick]}$/i)
    configure do |c|
      c.verbose   = ! c.verbose
    end
  end
end
#####

##### HELP / DOCUMENTATION #####
help_prefix = "(private)"
$help << [:"help", "#{help_prefix}  #{$bot_config[:bot_nick]} [!]help :: display help"]
on :channel, /\s*(#{$bot_config[:bot_nick]})+.+!?help/i do
  show_help(nick)
end
on :private, /help/ do
  show_help(nick)
end

helpers do
  def show_help(nick)
    $help.each_pair { |cmd,line| msg nick, "#{cmd.to_s}: #{line}" }
    $secret_help.each_pair { |cmd,line| msg nick, "#{cmd.to_s}: #{line}" }
  end
end
##############################

#### Venn Diagram ####
help_prefix = "(public|private)"
$help << [:"!venn", "#{help_prefix} !venn <#room1> <#room2> [#room3] :: Create link for venn diagram of room membership\n\tExtra info is given if run in private"]

helpers do
  def venn_query(roomlist)
    # Set flag to prevent multiple instances of this routine at one
    if (@venning ||= false) then
      msg nick, "I'm busy, try again in about 10 seconds!"
      puts "Turning down VENN request from #{nick} (busy)"
    else
      puts "#{message} for #{nick}"
      @venning = true
      # reset the hash of sets (arrays), for user names
      @userrooms = {}
      @remaining_room_queries = []
      # iterate over rooms in roomlist and create room list
      roomlist.split(" ").each do |room|
        if (room =~ /#[a-z0-9-]+/i)
          join room
          @userrooms[room.upcase.to_sym] = []
        end
      end
      # Check room list
      if ((@userrooms.keys.count < 2) or (@userrooms.keys.count > 3)) then
        msg @querier, "Only 2 and 3 circle venns are supported.  Specify exactly two or three rooms."
        @userrooms = {}
      else
        @remaining_room_queries = @userrooms.keys
        @userrooms.keys.each { |room| raw "who #{room} %cu" }
      end
    end
  end
end

on :private, /\s*!venn\s+(.*)$/i do |roomlist|
  @venn_private = true
  @querier = nick
  venn_query nick, roomlist
end

on :public, /\s*!venn\s+(.*)$/i do |roomlist|
  @venn_private = false
  @querier = channel
  venn_query nick, roomlist
end

# Handle a room query result
on :"354", // do
  @userrooms[mesg.params[1].upcase.to_sym] << mesg.params[2] if mesg.params[2] !~ /#{$bot_config[:bot_nick]}/i
end

# Handle an end of query message
on :"315", // do
  @remaining_room_queries.delete(mesg.params[1].upcase.to_sym)
  
  unless ( @sticky_rooms.include?(mesg.params[1].upcase.to_sym) ) then
    part(mesg.params[1].upcase.to_sym)
    puts("leaving #{mesg.params[1].upcase} - done peeking")
  end
  
  if (@remaining_room_queries.empty?) then
    # Now let's construct the arguments for google charts api
    # We need 7 values according to "http://code.google.com/apis/chart/docs/gallery/venn_charts.html"
    rooms = @userrooms.keys
    three_rooms = (@userrooms.count == 3)
    data = []
    data[0] = @userrooms[rooms[0]].count
    data[1] = @userrooms[rooms[1]].count
    data[2] = 0
    data[2] = @userrooms[rooms[2]].count if three_rooms
    
    intersection = @userrooms[rooms[0]] & @userrooms[rooms[1]] unless three_rooms
    data[3] = (@userrooms[rooms[0]] & @userrooms[rooms[1]]).count
    
    
    if (three_rooms) then
      data[4] = (@userrooms[rooms[0]] & @userrooms[rooms[2]]).count
      data[5] = (@userrooms[rooms[1]] & @userrooms[rooms[2]]).count
      data[6] = (@userrooms[rooms[0]] & @userrooms[rooms[1]] & @userrooms[rooms[2]]).count
      intersection = @userrooms[rooms[0]] & @userrooms[rooms[1]] & @userrooms[rooms[2]]
    end
    labels = rooms.join("|").gsub("#","")
    
    # Shrink data
    data.collect! { |x| x/10.0 }
    
    msg @querier, "http://chart.apis.google.com/chart?cht=v&chs=500x500&chd=t:#{data.join(",")}&chdl=#{labels}"
    if @venn_private then
      msg @querier, "set intersection [#{intersection.join(", ")}]"
      msg @querier, "membership:"
      @userrooms.each_pair { |room,members| msg @querier, "            #{room.to_s} has #{members.count}"}
    end
    @venning = false
  end
end
####################

#### WEATHER ALERT SYSTEM ####
## Organize data into a hash of WXAlert objects ##
def connect_wx_alerts
  @wx_alerts = {}
end

helpers do
  def publish_alerts(to,cmd,arg)
    url_arg = URI.escape(arg.to_s.chomp.strip)
    
    case
    when (cmd =~ /alerts?/i)
      @wx_alerts[arg.to_sym] ||= Wunderground::WXAlert.new("http://api.wunderground.com/auto/wui/geo/AlertsXML/index.txt?query=#{url_arg}")
      @wx_alerts[arg.to_sym].update!
      if @wx_alerts[arg.to_sym].alerts then
        @wx_alerts[arg.to_sym].alerts.each do |a|
          msg to, "A \"#{a[:description]}\" for #{arg} expires #{a[:expires]}. (http://www.wund.com/cgi-bin/findweather/getForecast?query=#{url_arg}##{a[:type]})}"
        end
      else
        msg to, "No alerts for #{arg}" 
      end
    when (cmd =~ /bulletin/i)
      @wx_alerts[arg.to_sym] ||= Wunderground::WXAlert.new("http://api.wunderground.com/auto/wui/geo/AlertsXML/index.txt?query=#{url_arg}")
      @wx_alerts[arg.to_sym].update!
      if @wx_alerts[arg.to_sym].alerts then
        msg to, "WX Bulletin for U.S. zipcode #{arg} has #{@wx_alerts[arg.to_sym].alerts.size} alerts:"
        @wx_alerts[arg.to_sym].alerts.each do |a|     
          msg to, "Description: #{a[:description]}"
          msg to, "Effective: #{a[:date]}"
          msg to, "Expires: #{a[:expires]}"
          a[:message].lines.each { |line| msg to, "Bulletin: #{line}" }
        end  
        msg to, "(http://www.wund.com/cgi-bin/findweather/getForecast?query=#{url_arg})}"
      else
        msg to, "No alerts for #{arg}" 
      end
    else
      # Output help
      puts "Implement help!"
    end #case
  end
end

help_prefix = "(public|private)"
$help << [:"!wx", "#{help_prefix}  !wx (alert|bulletin) <Zipcode> :: Show weather alert info for Zipcode\n\talert is terse, bulletin is verbose."]
on :channel, /!wx\s+([\#\w\-\_0-9]+)\s+(.*)$/ do |cmd,arg|
  publish_alerts channel, cmd, arg
end
on :private, /!wx\s+([\#\w\-\_0-9]+)\s+([\#\w\-\_0-9]+)/ do |cmd,arg|
  publish_alerts nick, cmd, arg
end

#######################
#### Dictionary System ####
## Organize data in a hash of hashes

def connect_dictionary
  @dictionaries = Hash.new
  if (File.exist?("isaac-dictionaries.yaml")) then
    @dictionaries = YAML.load_file("isaac-dictionaries.yaml")
  end
end

helpers do  
  # Dictionary sytem helpers
  def show_def(to,dict,term)
    msg to, "#{@dictionaries[dict.upcase.to_sym][term.upcase.to_sym]}" if @dictionaries and @dictionaries[dict.upcase.to_sym] and @dictionaries[dict.upcase.to_sym][term.upcase.to_sym]
  end
end
#  Listing and adding only supported as privmsg

help_prefix = "(private)"
$help << [:"!list", "#{help_prefix} !list [(terms|items) (in|for|from) <dict>] :: List dictionaries, or items in dictionaries"]
on :private, /\s*!list/i do
  unless @dictionaries then
    @dictionaries = {}
    puts "Created new dictionaries instance #{@dictionaries.inspect}"
  end
  if message =~ /\s*list\s+(terms|items)\s+(in|from|for)\s+([a-z]+)/i then
    # user is asking for items in a dictionary
    dict = message.scan(/\s*list (terms|items)\s+(in|from|for)\s+([a-z]+)/i)[0][2]
    puts "showing terms in #{dict}"
    @dictionaries[dict.upcase.to_sym] ||= {}
    msg nick, @dictionaries[dict.upcase.to_sym].keys.join(", ")
  else # must be asking for list of dictionaries
    puts "Listing Dictionaries for #{nick}"
    msg nick, @dictionaries.keys.join(", ")
  end
end

$help << [:"!define", "#{help_prefix} !define <term> in <dict> as <def> :: Defines a term in a dictionary"]
on :private, /\s*!define\s+([\#\w\-\_0-9]+)\s+in\s+([a-z]+)\s+as\s(.*)/i do |term,dict,defn| 
  unless @dictionaries then
    @dictionaries = {}
    puts "Created new dictionaries instance #{@dictionaries.inspect}"
  end
  
  nicktag = ""
  nicktag = " (#{nick})" if nick != $bot_config[:owner_nick]
  
  # Autocreate new dictionary in dictionaries
  @dictionaries[dict.upcase.to_sym] ||= {}
  @dictionaries[dict.upcase.to_sym][term.upcase.to_sym] = defn + nicktag
  puts "Defined #{term} in #{dict} as #{defn}"
end

# show defs
help_prefix = "(public|private)"
$help << [:"!show", "#{help_prefix}  !show <term> (for|in|of|from) <dict> :: Displays associated term definition"]
on :private, /\s*show\s+([a-z]+)\s+(for|in|of|from)+\s+([a-z]+)/i do |term,trash,dict| 
  show_def(nick,dict,term)
end

on :channel, /\s*show\s+([a-z]+)\s+(for|in|of|from)+\s+([a-z]+)/i do |term,trash,dict| 
  show_def(channel,dict,term)
end

#### MEANINGLESS BANTER ####
helpers do
  # Meaningless Banter Helpers
  def greet(to, john)
    gw = %w(hi hello greetings hey)
    g = gw[(rand * 10).to_i % 4]
    msg to, "#{g}, #{john}"
    puts "Greeted #{to}"
  end
end

# Fortune

help_prefix = "(public)"
$help << [:"!fortune", "#{help_prefix} #{$bot_config[:bot_nick]} !fortune :: Displays random quotes"]
on :channel, /\s*(#{$bot_config[:bot_nick]})+.+!fortune/i do
  fortune_command = "fortune -s"
  fortune_result = `#{fortune_command}`
  fortune_result.chomp!
  fortune_result.split("\n").each do |fortune_line|
    msg channel, fortune_line.chomp    
  end
end

# Vending machine (if a user asks me a question)
on :channel, /.*(#{$bot_config[:bot_nick]})+.*\?/i do
  msg channel, "Before I answer your questions, please swipe your credit card."
  puts "declined answering question: #{message} for: #{nick} in room: #{channel}"
end

# ways to say hello :
on :channel, /.*(hi|hello|greetings|hey)+\s+.*(#{$bot_config[:bot_nick]})+.*/i do
  greet(channel, nick)
end
on :channel, /.*(#{$bot_config[:bot_nick]})+.*(hi|hello|greetings|hey)+\s?/i do
  greet(channel, nick)
end
on :private, /(hi|hello|greetings|hey)+\s?/i do
  greet(nick, nick)
end