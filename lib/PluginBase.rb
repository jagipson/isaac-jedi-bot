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
  
  $bot.quit      => quit(t="")  Performs /quit with message        
  $bot.join      => join(*chn)  */join*s rooms. 'chn' is an Array      
  $bot.part      => part(*chn)  */part*s rooms. 'chn' is an Array
  
  $bot.topic     => topic(c,t)  Set topic 't' in channel 'c'
  $bot.mode      => mode(c,o)   Set mode option 'o' in channel 'c'
  $bot.kick      => kick(c,u,r) */kick*s channel, user, reason

  TODO: Document value-adds like automsg, etc.

=end

class PluginBase #:enddoc:
                 
  private
  
  #provide a default description
  @desc = "#{self.name} is indescribable!"
  def self.description(value)
    @desc = value.to_s
  end
  def self.desc
    @desc
  end
  
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
  
  def self.token(tok)
    # When a class is inheriting from me, register it's token
    @@global_tokens_catalog ||= Hash.new
    @token = self.validate_token(tok)
    @@global_tokens_catalog[@token] = self
  end
  def self.get_token
    @token
  end
  
  @default_command = :help
  def self.default_command(command_name = :help)
    @default_command = command_name.to_sym
  end
  def self.get_default_command
    @default_command ||= :help
  end
  
  def self.default_command_context(value = :auto)
    @default_command_context = value.to_sym
  end
  def self.get_default_command_context
    @default_command_context ||= :auto
  end
  
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
  
  @context = :auto
  # Needs to be :auto, or any of isaac's events
  def self.context(context = :auto)
    @context = context
  end
  
  def noop
    nil
  end
  # Accessor for class instance variable
  def self.commands
    (@commands ||= [])
  end

  
  # called by #initialize().
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
        #Register with global $bot
        m = self.method(meth.to_sym)
        $bot.on(c.to_sym, /^\s*!#{self.class.get_token.to_s}\s+#{meth.to_s}\s?(.*)$/i, &m)
      end
    end
    # Register default command
    if (self.class.get_default_command_context == :auto) then
      contexts = [:channel, :private] 
    else
      contexts = [self.class.get_default_command_context]
    end
    contexts.each do |c|
      m = self.method(self.class.get_default_command)
      $bot.on(c.to_sym, /^\s*!#{self.class.get_token.to_s}(.*)$/i, &m)
    end
  end
  protected
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
        m = self.method(:noop)
        $bot.off(c.to_sym, /^\s*!#{self.class.get_token.to_s}\s+#{meth.to_s}\s?(.*)$/i, &m)
      end
    end
    # Register default command
    if (self.class.get_default_command_context == :auto)  then
      contexts = [:channel, :private] 
    else
      contexts = [self.class.get_default_command_context]
    end
    contexts.each do |c|
      m = self.method(:noop)
      $bot.off(c.to_sym, /^\s*!#{self.class.get_token.to_s}(.*)$/i, &m)
    end
    # Unregister Token
    @@global_tokens_catalog.delete(self.class.get_token)
  end
  private
  def initialize
    register_commands
  end

  # Create accessors that users will expect to access $bot properties
  [:config, :irc, :nick, :channel, :message, :user, :host, :error].each do |item|
    eval(<<-EOF)
      def #{item}
        $bot.#{item}
      end
    EOF
  end
  def args
    match[0]
  end
  # Wrap other $bot methods
  #single argument methods in $bot
  %w(raw quit join part).each do |m|
    eval(<<-EOF)
      def #{m}(arg)
        $bot.#{m}(arg)
      end
    EOF
  end
  #two argument methods in $bot
  %w(msg action topic mode).each do |m|
    eval(<<-EOF)
      def #{m}(arg1, arg2)
        $bot.#{m}(arg1, arg2)
      end
    EOF
  end
  # automsg detects whether the sender is private or public and sends the 
  # message there
  def automsg(text)
    if channel.nil? then
      msg nick, text
    else
      msg channel, text
    end
  end
  
  # The only three arg method in $bot
  def kick(channel, user, reason=nil)
    $bot.kick(channel, user, reason=nil)
  end
  
  # TODO: I think this can safely be removed
  %w(helpers).each do |method|
    eval(<<-EOF)
      def #{method}(*args, &block)
        $bot.#{method}(*args, &block)
      end
    EOF
  end
  
  # Keep this method at bottom of class declaration.  All classes defined after
  # This will be registered as commands, automagically
  
  def self.method_added(method)
    # Maintain a list of added methods and their context
    (@commands ||= []) << [method, (@context ||= :auto)]
  end
  
  # I hope this method is completely overridden in the subclass, but this 
  # provides sane functionallity if not
  def help
    if channel.nil? then # list private commands
      commands = self.class.commands.select {|c| [:private, :auto].include?(c[1]) }
    else # list channel commands
      commands = self.class.commands.select {|c| [:channel, :auto].include?(c[1]) }
    end
    automsg "!#{self.class.get_token} (#{ commands.map{|c| c[0].to_s }.join("|") })" if commands && commands.size > 0
  end

end