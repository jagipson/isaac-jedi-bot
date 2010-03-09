=begin rdoc
= PluginBase Abstract Class
Provides the framework for writing plugins that can be loaded into RubOt. This
is an abstract class.  Do not attempt to instantiate this class directly.

The creation of subclasses of PluginBase is how plugins are created. Do not
instantiate your own subclasses. Your subclass will be instantiated as a
plugin object when it is loaded.

= Creating RubOt Plugins

To create a RubOt Plugin, you must create a subclass of PluginBase, configure
it, and define methods which will then become commands.

The best way to get started is by demonstration.

     1	  class Greets < PluginBase
     2	    description "Silly example plugin"
     3	    token       :greet
     4	    
     5	    context  :auto
     6	    def help
     7	      automsg "Additional features available in " + 
     8	              "private room then !greet to get list"
     9	      super
    10	    end
    11	  
    12	    def hi
    13	      automsg "#{nick} said hi!"
    14	    end
    15	    
    16	    context :channel
    17	    def hello
    18	      automsg "Hello, #{nick}"
    19	    end
    20	  
    21	    context :private 
    22	    def special
    23	     msg nick, "Even though you lick windows on " +
    24	               "the short bus, to me you are still special!" 
    25	    end
    26    end

== line... by... line...

=== Lines 1-3:

On line 1, you define your subclass of PluginBase (in the example
it's Greets). This will be the _name_ of your plugin. This is very important:

<b>Your file must be given exactly the same name as your plugin, with a _.rb_
extension</b>. For this example, the plugin file _must_ be named
<tt>Greets.rb</tt> or it will not work. Yes, it *is* case-sensitive.

Line 2 shows proper use of +description+. Implementing +description+ is
entirely voluntary, but if you don't define one, the PluginBase will for you,
because it is needed for the global help system (activated by +help!+ in IRC).

The +token+ definition on line 3 is absolutely necessary. The _token_ is what
is used by RubOt to determine which module to route your command message to.
For example, to use any functionallity in _Greets_, the "+!greet+" token must
be the first text on the IRC line. Don't include the bang (!) when you define
the token here, but do prefix the token with bang (!) in IRC.

Another setting, not shown, takes the form of:

<tt>       default_command     :help </tt>

This is actually the default which is used if you do not
override it with something else.  The default_command is called whenever a line
starts with <tt>!<token></tt> but has an invalid command, or no command at all.
If you do not define a +help+ command method, then a terse one will be created
automatically (see "Help Behavior" and #help methods).  Overriding this is
useful if you create a plugin that has only one command, and requires no help.
An additional setting, is:

<tt>       default_command_context     :auto </tt>

If you don't add this configuration, then it defaults to +:auto+. Only use
this setting if you want to change the how the plugin's default_command
responds.

=== Lines 5-25

The remainder of this file defines the commands that the plugin will listen
for. Commands actually are Ruby methods of your plugin class. In _Greets_, the
commands are _help_, _hi_, _hello_, and _special_.

==== Help Behavior

A quick word on _help_: We prefer that you define _help_, but if you don't,
PluginBase will do it for you. The automatic help is terse, but lists the
available commands. You can use the automatically generated help within your
help by calling +super+. The automatically generated help is also context
sensitive (in the sense of RubOt context which is covered below). This means
that if you run the +help+ command in a public IRC channel, only the commands
defined in the _channel_ and _auto_ contexts will be displayed. Conversely, if
you run the +help+ command in private, only the commands defined in the
_private_ and _auto_ contexts will be displayed.

==== Contexts Explained

Line 5 sets the _context_ to +:auto+. This is not really necessary here,
because +:auto+ is the default context, and this statement is usually only
used to set the context back to +:auto+ after it has been set to something
else. All commands defined in the +:auto+ context respond whether the command
was sent in +:channel+ or +:private+. The +:channel+ and +:private+ contexts
are for defining commands that may _only_ be sent from a channel _or_ private.

Another special context is +:helper+. All methods defined in the +:helper+
context are available to other methods in your plugin, but cannot be run as a
command directly from IRC.  See "Hiding Methods."

==== Accessing Data and Performing Actions

The single +Isaac::Bot+ instance is globally accessible via the global +$bot+
variable. To keep your code legible, the following mappings have been made:

===== Accessing Isaac::Bot instance internals - You should never need these
  $bot.config    => config
  $bot.irc       => irc
  
===== Variables for use in command definitions:
  
  $bot.nick      => nick        IRC nick of the person who issued the command
  $bot.channel   => channel     IRC channel command was issued in 
                                (or nil if the command was in private)
  $bot.message   => message     complete IRC message from _nick_
  $bot.user      => user        Username of message sender
  $bot.host      => host        Hostname of message sender      
  $bot.error     => error       Error (used in _:error_ context)
  $bot.match[0]  => args        Everything *after* the command in the message
  
===== Methods for performing actions:
  
  $bot.raw       => raw(txt)    Send raw message to IRC Server
  $bot.msg       => msg(n,t)    Send text 't' to 'n' (n can be nick or channel)
  $bot.action    => action(n,t) Same as $bot.msg only sends */me* action 
  
see also #automsg   
  
  $bot.quit      => quit(t="")  Performs /quit with message        
  $bot.join      => join(*chn)  */join*s rooms. 'chn' is an Array      
  $bot.part      => part(*chn)  */part*s rooms. 'chn' is an Array
  
  $bot.topic     => topic(c,t)  Set topic 't' in channel 'c'
  $bot.mode      => mode(c,o)   Set mode option 'o' in channel 'c'
  $bot.kick      => kick(c,u,r) */kick*s channel, user, reason

===== Hiding Methods

By default, all instance methods defined in the plugin class automatically
become IRC plugin commands.  

If you want to define a method that other methods can call, but you do not
want the method to be visible or accessible as a command in IRC, then you must
hide the method.  You can hide methods in these ways:
* Any method whose name begins with an underscore (_) will be hidden
* Set <tt>context :helper</tt> in your plugin class declaration. All methods defined under the _helper_ context will be hidden regardless of its name.  You can resume defining command methods by setting the context to something else (e.g. <tt>context :auto</tt>)

=end

class PluginBase
  # This abstract class does 3 things (for it's subclasses)
  # 1. Sets up a standard syntax (!<token> <command> [args]) for creating IRC
  #    Bot events.
  # 2. It makes data and methods from Isaac::Bot accessible so that subclasses
  #    can benefit from the IRC commands, such as Isaac::Bot#msg and
  #    Isaac::Bot#join, etc.  It also provides a more programmer-friendly
  #    environment, as Isaac::Bot sets up a Domain Specific Language (DSL) for
  #    bot creation, RubOt reverts back to a more Rubyish environment which is
  #    Friendlier for programmers.  RubOt also, adds functionallity such as the
  #    ability to create a command that responds in private and in channel.  
  #    Isaac::Bot required you to create two seperate events for this.
  # 3. It provides a plugin framework for Isaac::Bot.  In RubOt, all bot
  #    functionallity is implemetned in loadable plugins.  The plugin
  #    archetecture allows loading and unloading plugins while connected to the
  #    IRC server, without stopping the bot core.  It also provides error handling
  #    so that (hopefully) errors in plugins are simply logged to the bot console
  #    and are not likely to result in crashing and disconnecting the bot. 
  
  # PluginBase adds commands to an Isaac::Bot instance as events using the
  # Isaac::Bot#on method. If the bot is run via RubOt.rb (just like issac.rb),
  # then a $bot global is associated with your bot instance.  Normally, we 
  # would just access the global $bot, however, for the convenience of running
  # tests, and for some as-yet unimagined use of this library, and in the name
  # of encapsulation, we will use a local @bot instance.  If @bot isn't passed
  # to the constructor, then $bot will be used.  Once a PluginBase is 
  # instantiated, @bot cannot be changed.
  def initialize(instance_bot=nil)
    @bot = instance_bot || $bot
    raise "warning: PluginBase was instantiated directly" if self.class == PluginBase
    return self
  end
  
  private
  
  #
  #  Plugin Configuration Accessors
  #
  
  #provide a default description which should be overridden in the sublass
  @desc = "#{self.name} is indescribable!"
  # Description class-object variable accessors
  def self.description(value)
    @desc = value.to_s
  end
  def self.desc
    @desc ||= "#{self.name} is indescribable!"
  end
  
  # Validate the token, and return the token in symbol form.  A valid token 
  # is a non-nil, non-empty string or symbol object that begins with a letter
  # and contains only letters and digits, thereafter.  Tokens must also be unique
  # per each RubOt instance. Invalid tokens raise errors.  
  def self.validate_token(tok)
    # Guarantee that a token was established
    if (tok.nil? or tok.to_s !~ /^[A-Za-z]+[A-Za-z0-9]*$/i ) then
      raise "Bad token (#{tok.to_s}) defined in Plugin (#{self.name})"
    
    # Guarantee that a token is unique by checking against registered tokens
    elsif (@@global_tokens_catalog[tok.to_s.downcase.to_sym] and
           @@global_tokens_catalog[tok.to_s.downcase.to_sym] != self)
      raise "Non-unique token (#{tok.to_s.downcase}) in #{self.name}. " +
        "Already used by #{@@global_tokens_catalog[tok.to_s.downcase.to_sym]}"
    else
      return tok.to_s.downcase.to_sym
    end
  end
  # token class-object variable accessors
  def self.token(tok)
    # @@global_token_catalog is used to make sure that all subclasses of
    # PluginBase have unique @tokens.
    @@global_tokens_catalog ||= Hash.new
    @token = self.validate_token(tok)
    @@global_tokens_catalog[@token] = self
  end
  # TODO: Once tests written, use inherited() hook to initialize token to self.class.to_s.downcase; a sensible default
  def self.get_token
    @token
  end
  
  # declare the default default_command as help, in case the subclass forgot to.
  @default_command = :help
  # default_command class-object variable accessors
  def self.default_command(command_name = :help)
    @default_command = command_name.to_sym
  end
  def self.get_default_command
    @default_command ||= :help
  end
  
  # default_command_context class-object variable accessors
  def self.default_command_context(value = :auto)
    @default_command_context = value.to_sym
  end
  def self.get_default_command_context
    @default_command_context ||= :auto
  end
  
  # Needs to be :auto, or any of isaac's events
  # context class-object variable accessors
  def self.context(context = :auto)
    @context = context
  end
  
  #
  #  Implement default_commands
  #
  
  # this hook method is part of Ruby.  I am overriding it here to run the 
  # default command, which is usually some sort of help.
  def missing_method(name, *args, &block)
    warn "missing method #{name} default -> #{@default_command}"
    if self.respond_to?(@default_command)
      # By definition, the default method must be able to be invoked with no
      # args:
      method(@default_command).call
    else
      super
    end
  end
  
  #
  #  Wrap command-methods in an error handler (hard candy shell) 
  #

  # Wrap a method object in an error handler and return a proc
  def self.meth_wrap_proc(m)
    return nil unless m.kind_of?(Method)
    return Proc.new do
      begin
        m.call
      rescue Exception => e
        puts "An error occured:#{e.message}\n#{e.backtrace.join("\n")}"
        puts "resuming..."
      end
    end
  end  
  
  # @commands class-object variable accessor
  # @commands holds a list of the methods that respond to IRC events
  def self.commands
    (@commands ||= [])
  end
  
  ##### Start Protected Methods
  
  protected
  
  # registers command-events for all non-hidden command methods in your plugin with
  # the global $bot object.  The only time this should be run is to enable commands
  # while loading plugin, or reenable commands for a plugin whose commands have been unregistered by 
  # #unregister_commands.  This is invoked
  # for you by the Core plugin when you issue a <tt>!do load_plugin ...</tt> command
  # so, unless you are writing a plugin that manages other plugins, you don't need
  # to run this directly.
  def register_commands
    #first revalidate Class for good token, to ensure it was set
    self.class.validate_token self.class.get_token
    
    # Register defined commands
    self.class.commands.each do |command|
      meth, context = command
      puts "Registering #{meth} for #{self.class.name} for event #{context}"
    
      # This allows 'auto' for commands to work in channel and private
      if context == :auto
        contexts = [:channel, :private] 
      else
        contexts = [context]
      end
      contexts.each do |c|     
        # Wrap m in an error handler:
        bloc = self.class.meth_wrap_proc(self.method(meth.to_sym))
        #Register with global $bot as an event
        @bot.on(c.to_sym, /^\s*!#{self.class.get_token.to_s}\s+#{meth.to_s}\s?(.*)$/i, &bloc)
      end
    end
    # Register default command
    if (self.class.get_default_command_context == :auto) then
      contexts = [:channel, :private] 
    else
      contexts = [self.class.get_default_command_context]
    end
    contexts.each do |c|
      bloc = self.class.meth_wrap_proc(self.method(self.class.get_default_command))
      @bot.on(c.to_sym, /^\s*!#{self.class.get_token.to_s}(.*)$/i, &bloc)
    end
  end
  
  # unregisters command-events that have previously been registered by #register_commands
  # from the global $bot object.  The only time this should be run is to disable
  # a loaded plugin, or immediately prior to unloading a plugin.  This is invoked
  # for you by the Core plugin when you issue a <tt>!do unload_plugin ...</tt> command
  # so, unless you are writing a plugin that manages other plugins, you don't need
  # to run this directly.
  def unregister_commands
    # Register defined commands
    self.class.commands.each do |command|
      meth, context = command
      puts "Unregistering #{meth} for #{self.class.name} for event #{context}"
      
      # This allows 'auto' for commands to work in channel and private
      if context == :auto
        contexts = [:channel, :private] 
      else
        contexts = [context]
      end
      contexts.each do |c|
        #Register with global $bot
        @bot.off(c.to_sym, /^\s*!#{self.class.get_token.to_s}\s+#{meth.to_s}\s?(.*)$/i)
      end
    end
    # Register default command
    if (self.class.get_default_command_context == :auto)  then
      contexts = [:channel, :private] 
    else
      contexts = [self.class.get_default_command_context]
    end
    contexts.each do |c|
      @bot.off(c.to_sym, /^\s*!#{self.class.get_token.to_s}(.*)$/i)
    end
    # Unregister Token
    @@global_tokens_catalog.delete(self.class.get_token)
  end
  
  private
  # These are documented at the top of the file in the big rDoc block
  # Create accessors that users will expect to access $bot properties
  [:config, :irc, :nick, :channel, :message, :user, :host, :error].each do |item|
    eval(<<-EOF)
      def #{item}
        @bot.#{item}
      end
    EOF
  end
  def args
    @bot.match[0]
  end
  # The only three arg method in $bot
  def kick(channel, user, reason=nil)
    @bot.kick(channel, user, reason=nil)
  end
  # Wrap other $bot methods
  #single argument methods in $bot
  %w(raw quit join part).each do |m|
    eval(<<-EOF)
      def #{m}(arg)
        @bot.#{m}(arg)
      end
    EOF
  end
  #two argument methods in $bot
  %w(msg action topic mode).each do |m|
    eval(<<-EOF)
      def #{m}(arg1, arg2)
        @bot.#{m}(arg1, arg2)
      end
    EOF
  end
  
  #### More Protected Methods
  protected
  
  # sends a message either to a channel _or_ to private, depending on where the 
  # command was invoked.  If you have defined a command method in +:auto+ context,
  # #automsg will send the _text_ to the channel if the command was run in the 
  # channel, and send the _text_ to private (query) if the command was run using 
  # a private message.  This is useful for the +:auto+ context.
  def automsg(text)
    if channel.nil? then
      msg nick, text
    else
      msg channel, text
    end
  end
  
  #
  #  Meta-programming hooks
  #
  
  # Keep this method at bottom of class declaration.  All classes defined after
  # This will be registered as commands, automagically
  
  def self.method_added(method)
    # Maintain a list of added methods and their context
    @context ||= :auto
    (@commands ||= []) << [method, (@context)] unless @context == :helper or 
                                                      method =~ /^_/ or
                                                      method =~ /initialize/
  end
  
  #
  #  Set Context, then Provide default help scaffold using reflection
  #
  
  context :auto
  
  # provides a quick and dirty list of all commands in a plugin.  This method is 
  # a scaffold of sorts.  You should really override this method in your plugin class
  # to provide better information to your users.
  # This method is context sensitive (in the Rubot sense of context) in that if 
  # <tt>!<token> help</tt> is called in a channel it only lists commands available 
  # in the channel, but if it is called in private, it lists only commands available
  # in private.
  def help
    if channel.nil? then # list private commands
      commands = self.class.commands.select {|c| [:private, :auto].include?(c[1]) }
    else # list channel commands
      commands = self.class.commands.select {|c| [:channel, :auto].include?(c[1]) }
    end
    automsg "!#{self.class.get_token} (#{ commands.map{|c| c[0].to_s }.join("|") })" if commands && commands.size > 0
  end

end