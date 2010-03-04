class PluginBase

  def self.plugin_name(value)
    @name = value.to_s
  end
  def self.name
    @name
  end
  
  def self.token(tok)
    @token = tok.to_s
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

  def register_commands
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
        $bot.on(c.to_sym, /^\s*!#{self.class.get_token.to_s}\s+#{meth.to_s}\s?(.*)$/, &m)
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
      $bot.on(c.to_sym, /^\s*!#{self.class.get_token.to_s}(.*)$/, &m)
    end
  end
  
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
        $bot.off(c.to_sym, /^\s*!#{self.class.get_token.to_s}\s+#{meth.to_s}\s?(.*)$/, &m)
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
      $bot.off(c.to_sym, /^\s*!#{self.class.get_token.to_s}(.*)$/, &m)
    end
  end
  
  def initialize
    register_commands
  end

  # Create accessors that users will expect to access $bot properties
  [:config, :irc, :nick, :channel, :message, :user, :host, :match, :error].each do |item|
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