=begin
Augments the Kernel behaviour of a command-line tool/utility programmed in
Ruby by trapping SIG_INT (Ctrl-C) from STDIN and requiring it to be used twice
within 10 seconds to prevent accidental program terminations; and creating a
global logger instance for log messages. This module overrides Kernel#puts,
Kernel#warn and Kernel#p to use Logger#info, Logger#warn and Logger#debug,
respectively, so if your program has a text-user interface (TUI) that prints
to and takes commands from STDIN/STDOUT, this module *might* not me the one
you're looking for. 
=end


module OverridesSTDIO 
  require 'logger'
  

  $logr = Logger.new(STDOUT)

  # Map out other logger attributes and methods to module level
  [:unknown, :info, :fatal, :error, :debug].each do |meth|
    send :define_method, meth do |progname, &block|
      $logr.send meth, progname, &block
    end
  end
  [:warn?, :info?, :fatal?, :error?, :debug?].each do |meth|
    send :define_method, meth do
      $logr.send meth
    end
  end
  
  alias kernel_puts puts
  alias kernel_warn warn
  alias kernel_p    p
  
  def puts(*args)
    args.each { |arg| $logr.add(Logger::INFO, arg.to_s) }
    nil
  end

  def warn(*args, &block)
    if block_given? then # Assume call was meant for logger#warn
         $logr.warn args[0], &block
        else # Assume that user was trying to call Kernel#warn
         args.each { |arg| $logr.add(Logger::WARN, arg.to_s) }
        return nil
    end
  end
  
  def p(*args)
    args.each { |arg| $logr.add(Logger::DEBUG, arg.inspect) }
    nil
  end
  
  # Capture ^C, 
  trap "INT" do 
     $interrupts ||= 0 # initialize 
     $interrupts += 1 # increment 
     if $interrupts >= 2 then 
       if $last_interrupt < (Time.now - 10) then # Interrupt was old 
         $interrupts = 1 
       else puts "" 
         exit 0 
       end 
     end 
     $last_interrupt = Time.now 
     warn "\nCaught Interrupt. [CTRL]-C again exits"
  end 
end