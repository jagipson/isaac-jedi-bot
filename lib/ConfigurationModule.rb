require 'yaml'
# Read the configuration file
DEFAULT_CONF = 'jedbotcnf.yaml'
# TODO: Refactor The configuration module into a Class.
# TODO: Make the config class auto-save data when changed.
def configuration_from_file(config_file=DEFAULT_CONF)
  
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
  else
    warn "Unable to locate config #{config_file}.  Using defaults."
    config_root = {}
  end  
  
  # Make sure initial nick is set
  if (not config_root[:bot_nick]) then
    config_root[:bot_nick] = "UnnamedBot_#{(rand * 10000).to_i}"
    warn "No setting for BOT_CONFIG[:bot_nick].  Using #{config_root[:bot_nick]}"
  end
  
  # Make sure owner nick is set
  if (not config_root[:owner_nick]) then
    config_root[:owner_nick] = ENV["USER"]
    warn "No setting for BOT_CONFIG[:bot_nick].  Using #{config_root[:owner_nick]}"
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
      warn "No #{setting} setting for BOT_CONFIG[:bot_nick]. Please check #{config_file}"
      fatal_errors_occured = true
    end
  end
  
  config_root[:nickserv_secret] ||= ""
  
  write_configuration(config_root, config_file)
  exit if fatal_errors_occured
  return config_root
end

def write_configuration(config_root, config_file=DEFAULT_CONF)
  File.open(config_file, "w") { |f| YAML.dump(config_root, f) }
end

module BotExtensions
  # Define new off() in classes that include this module
  def off(event, match=//)
    match = match.to_s if match.is_a? Integer
    (@events[event] ||= []).delete_if {|a| a[0] == Regexp.new(match) }
  end
end
$bot.extend BotExtensions

# Capture ^C, 
trap "INT" do
  $interrupts ||= 0 # initialize
  $interrupts += 1 # increment
  if $interrupts >= 2 then
    if $last_interrupt < (Time.now - 10) then # Interrupt was old
      $interrupts = 1
    else
      exit 0
    end
  end
  $last_interrupt = Time.now
  warn "\nCaught Interrupt.  [CTRL]-C again exits"
end
