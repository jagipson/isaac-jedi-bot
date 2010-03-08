class Banter < PluginBase
description     "Provide hours of empty entertainment with random quotes" 
token           :fortune
default_command :fortune

  context :auto
# Requires fortune to be loaded on your system, but will not cause problems (other than non-functioning) if it is not installed.
  def fortune
    fortune_command = "fortune -s"
    fortune_result = `#{fortune_command}`
    fortune_result.chomp!
    fortune_result.split("\n").each do |fortune_line|
      automsg fortune_line.chomp    
    end
  end
  
  def help
    automsg args
  end
end
