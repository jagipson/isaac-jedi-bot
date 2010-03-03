class Core < PluginBase
  plugin_name :core
  token       :do
  
  context :private
  
  def fortune
    fortune_command = "fortune -s"
    fortune_result = `#{fortune_command}`
    fortune_result.chomp!
    fortune_result.split("\n").each do |fortune_line|
      msg channel, fortune_line.chomp    
    end
  end
end