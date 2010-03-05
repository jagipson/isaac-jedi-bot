class Banter < PluginBase
description     "Provide hours of empty entertainment with random quotes" 
token           :fortune
default_command :fortune

  context :auto
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
