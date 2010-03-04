class Greets < PluginBase
  plugin_name :greeter
  token :greet
  context :auto
  def help
    automsg "Additional features available in private room then !greet to get list"
    super
  end
  def hi
    automsg "#{nick} said hi!"
  end
  def hello
    automsg "Hello, #{nick}"
  end
 context :private 
  def special
   msg nick, "Even though you lick windows on the short bus, to me you are still special!" 
  end
end
