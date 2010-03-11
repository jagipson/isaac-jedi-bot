# encoding: utf-8
require_relative 'PluginBase.rb'

class Core < PluginBase
  description     "Core plugin for administrative tasks."
  token           :do
  default_command :help
  
  # helper method to print usage for a command in this plugin
  def _usage(cmd)
    "!#{self.class.get_token} #{cmd.downcase} "
  end
  
  def help
    # warning, use non-breaking spaces in this method.
    cmd = args.strip.split(" ")[0] # get first word in args
    case cmd
    when /^(join)|(part)$/i
      m = [] << "<#room1> [#room2]...[#roomN]"
      m      << "args: one or more space-delimited IRC rooms"
      m      << "#{cmd.strip}s IRC rooms."
    when /^hangup$/i
      m = [] << " " # empty string (no args)
      m      << "disconnect and terminate RubOt"
    when /^toggle_verbosity$/i
      m = [] << " "
      m      << "toggle Isaac::Bot engine's verbose console logging"
    when /^(un)?load(_plugin)?$/i
      m = [] << "<PlugInFileName.rb>"
      m      << "args: valid file name containing a RubOt plugin"
      m      << "#{$&.capitalize}s the named plugin.  Don't forget the filename extension (.rb)"
    when /list_plugins/i
      m = [] << " "
      m      << "prints a table listing all loaded plugins"
    else
      command_lists = {}
      command_lists[:private] = self.class.commands.select {|c| [:private].include?(c[1]) }
      command_lists[:public] = self.class.commands.select {|c| [:channel].include?(c[1]) }
      command_lists[:both] = self.class.commands.select {|c| [:channel].include?(c[1]) }
      # only print help for this plugin to private
      # get the length of the longest command
      cmd_len = command_lists.values.flatten.map { |v| v.size }.max
      cmd_len += self.class.get_token.to_s.length # add in length of token
      cmd_len += "! ".length # add in length of bang!-space prefix
      cmd_len = [cmd_len, "Command".length].max # <= decides on column width
      msg nick, "Command".ljust(cmd_len, ' ') + ' ' + "Access"
      msg nick, ("-" * "Command".length).ljust(cmd_len, ' ') + ' ' + ("-" * "Access".length)
      [:private, :public, :both].each do |l|
        command_lists[l].each do |i| 
          msg nick, "!#{self.class.get_token.to_s} #{i[0].to_s}".ljust(cmd_len, " ") + " " + l.to_s
        end
      end
      msg nick, " " # send blank line
      msg nick, "For help in individual commands, use !do help <command>"
      return
    end
    # Process non 'else' help
    msg(nick, _usage(cmd) + m.shift)
    while (n = m.shift) do
      msg nick, n
    end
  end
     
  context :private
  def join
    args.split(" ").each do |room|
      if (nick =~ /^#{BOT_CONFIG[:owner_nick]}$/i) and (room =~ /#[\w-]+/)
        super room
        puts "Joining #{room}"
      end
    end
  end

  def part
      args.split(" ").each do |room|
      if (nick =~ /^#{BOT_CONFIG[:owner_nick]}$/i) and (room =~ /#[\w-]+/)
        super room
        puts "Parting #{room}"
      end
    end
  end

  def hangup 
    if ($bot.nick =~ /^#{BOT_CONFIG[:owner_nick]}$/i)
      quit("Disconnecting")
      puts "Owner hangup"
    end
  end

  def toggle_verbosity 
    if (nick =~ /^#{BOT_CONFIG[:owner_nick]}$/i)
      $bot.configure do |c|
        c.verbose = ! c.verbose
        puts "Verbosity:#{c.verbose.to_s}"
      end
    end
  end

  def load_plugin(plugin_list_arg=nil)
    @plugins ||= {}
    plugin_list = plugin_list_arg || args
    plugin_list.split(" ").each do |plugin|
      plugin_file = $system_root + "/plugins/" + plugin
      plugin_file += ".rb" unless plugin =~ /.*\.rb/
      if File.exist?(plugin_file) then
        # Plugin's assume that the Classname = filename w/o .rb extension
        begin
          load plugin_file
          puts "About to register plugin #{plugin.inspect}"
          sym = plugin.downcase.sub(/.rb$/,"").to_sym
          self.instance_eval %Q{ @plugins[sym] = #{plugin}.new }
          @plugins[sym].register_commands
          msg nick, "#{plugin} loaded.  Default command: !#{@plugins[sym].class.get_token} #{@plugins[sym].class.get_default_command}"
        rescue Exception => e
          p e
          msg nick, "Unable to load plugin #{plugin}. Check logs"
        end
      else
        msg nick, "Unable to find plugin #{plugin_file}; PWD=#{ENV["PWD"]}"
      end
    end
  end
  # TODO: Plugins are not getting unloaded properly, that is, some info remains and reloads don't reload the new code
  def unload_plugin
    @plugins ||= {}
    args.split(" ").each do |plugin|
      plugin.sub!(/.rb$/,"")
      begin
        @plugins[plugin.downcase.to_sym].unregister_commands
        @plugins.delete(plugin.downcase.to_sym)
        msg nick, "#{plugin} unloaded." 
      rescue => problem
        puts problem
        msg nick, "Unable to unload plugin #{plugin}. Check logs"
      end
    end
  end
  
  #--
  # Unicode Non breaking spaces are used in this method to 'fool' the isaac library
  # into allowing us to have consecutive spaces.  the parse() method in isaac has a
  # side effect of squashing multiple consecutive spaces into one.  This circumvents
  # that effect, so I can print formatted tables
  def list_plugins
    # Always responds in private
    msg nick, "loaded plugins in order of appearance: "
    #IMPORTANT Spaces in the next line are NON-Breaking (not normal space char) 
    msg nick, "   Token Name            Description"
    ([self]+(@plugins||={}).values).each do |i| #IMPORTANT Spaces in the next line are NON-Breaking (not normal space char) 
      msg nick, "#{("!" + i.class.get_token.to_s).rjust(8, " ")} #{i.class.name[0..13].ljust(15, " ")} #{i.class.desc}"
    end
  end
  
  context :hidden
  # most plugins don'e need to override initialize, but this one does, so it
  # can self-register.  When overriding initialize, call super or it breaks
  def initialize(instance_bot=nil)
    super instance_bot
    
    # Since Core registers the commands of plugins that it loads, and it loads
    # itself, it must also register itself.  Other plugins don't need this.
    register_commands
  end
end
# This instance is created only because this Class is not loaded via the 
# !do load_plugins or (as yet not implemented, autoloader plugin).  In
# fact, this plugin contains the instructions for the load_plugin command so
# it is an exception to the rule.  We instantiate core here.  Don't instantiate
# any other plugins in any other plugin class definitions, because the object
# will not be used by the system.
core = Core.new

# Using isaac events, hook root "!help" and send to core help.
# Don't do anything like this in non Core plugin
on :channel, /\s*!help/i do
  core.list_plugins
end
on :private, /\s*!help/i do
  core.list_plugins
end
