# encoding: utf-8

class Core < PluginBase
  description     "Core plugin for administrative tasks."
  token           :do
  default_command :help
  # TODO: Override help() so it shows complete command explainations
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
        part room
        super "Leaving #{room}"
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

  def load_plugin
    @plugins ||= {}
    args.split(" ").each do |plugin|
      if File.exist?(plugin) then
        load plugin
        # Plugin's assume that the Classname = filename w/o .rb extension
        begin
          puts "About to register plugin #{plugin.inspect}"
          self.instance_eval %Q{ @plugins[plugin.downcase.to_sym] = #{plugin[0..-4]}.new }
        rescue 
          p $!
          msg nick "Unable to load plugin #{plugin}. Check logs"
        end
      else
        msg nick, "Unable to find plugin #{plugin}; PWD=#{ENV["PWD"]}"
      end
    end
  end
  
  def unload_plugin
    @plugins ||= {}
    args.split(" ").each do |plugin|
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
