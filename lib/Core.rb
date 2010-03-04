class Core < PluginBase
  plugin_name :core
  token       :do
  default_command :help
#  TODO: The methods in here should only work for owner. Need to fix event registraion regex somehow to have an option for owner commands 
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
        @plugins[plugin.downcase.to_sym] = nil
        msg nick, "#{plugin} unloaded." 
      rescue => problem
        puts problem
        msg nick, "Unable to unload plugin #{plugin}. Check logs"
      end
    end
  end
  
  def list_plugins
    msg nick, "loaded plugins: #{ (@plugins ||= {}).map {|p| p.to_s}.join(", ") }" 
  end
end
# This instance is created only because this Class is not loaded via the 
# !do load_plugins or (as yet not implemented, autoloader plugin).  In
# fact, this plugin contains the instructions for the load_plugin command so
# it is an exception to the rule.  We instantiate core here.  Don't instantiate
# any other plugins in any other plugin class definitions, because the object
# will not be used by the system.
core = Core.new
