#:stopdoc: 
# This is excluded via .gitignore - should only be a local file
class TestPlug < PluginBase
description     "For Programmer Testing" 
token           :test
default_command :help

  context :private
  def debug_events
    e =  @bot.instance_variable_get(:@events)
    puts "#{e.keys.count} event types:"
    e.keys.each do |k|
      puts "Event Type: #{k}: #{e[k].count} events"
      e[k].each do |mp_pair|
        puts "    #{mp_pair[0]}       #{mp_pair[1]}"
      end
    end
  end
  
  context :helper
  def nosee
    puts "You no see this"
  end
end
