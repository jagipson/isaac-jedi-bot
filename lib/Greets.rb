class Greets < PluginBase
  # Plugins Must Do These:
  plugin_name      :greeter  # This will tie into the future top-level help system
  token            :greet    # token is how commands get routed to your plugin, so
                             # with this token, the command syntax will be:
                             #   !greet hi
  default_command  :wazzup
 
  def self.learn_greeting name, &block
    if (nick == $bot_config[:owner_nick]) then  
      self.class.send(:define_method, name, &block)
    end # if
  end
 
end
 
# The problem with all this is that you instantiate your class to start 
# configuring it.  That instance will be thrown away.  The instance that is
# Kept and used by the plugins system is the instance created later;
# refer to RubOtCore.rb:49.  This is where .new is called on a plugin class, and 
# it is rather anonymously stuffed in a @plugins[] Array.
 
# the Core plugin is probably a bad example for people to us to write plugins,
# unless they want to replace or change the core.
 
# This instance will exist as a local var inside RubItCore.rb defined at line
# 45 where the load statement runs this file, and deallocated after line 59 when
# the block that starts on line 43 finishes, and it goes out of scope.
 
# Code at the bottom of your plug-in file WILL be evaluated during 'load plugin' on 
# line 45, however it should only be used modify the Class, not any instances.
 
# <strikeout>instance_of_greet_class = Greet.new</strikeout>
 
# This will "teach" that instance of Greet (only) how to do :hi :hello and :wazzup
# It is very very very similar to how you magically create your 'features' in the
# Greets by using PluginBase.

# All that having been said, it will still fail because the you're adding new
# object methods to the class and (if don't understand why, but) the context
# seems to go out of scope, so to get it working, I set the context before adding
# each method to a class when outside the class. (inside the class, the context
# is sticky, and defaults to :auto)
 
[:hi, :hello, :wazzup].each do |item|
  new_method = %Q{context :auto
                  def #{item}()
                    automsg "#{item.capitalize}, by warm blooded friend with moniker of \#{nick}"
                  end }
                  puts "having \n#{Greets.commands.inspect}"
                  puts "Adding \n#{new_method}"
  Greets.class_eval(new_method)  
end
