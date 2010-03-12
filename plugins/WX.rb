class WX < PluginBase
  token         :wx
  description   "Weather Information"
  
  def initialize
    super
    require_relative 'wx_alert.rb'
    require 'uri'
    require 'base64'
    @wx_alerts = {}
    @wx_watch = []
    @watcher_interval = 600
    
    @mutex = Mutex.new
    
    # Begin watcher thread
    Thread.new do
      while  true do
        # Sleep for watcher interval
        sleep @watcher_interval
        #Do alerts
        @wx_watch.each do |query,dest,cookie|
          @mutex.synchronize do
            arg = query
            url_arg = URI.escape(arg.to_s.chomp.strip)
            @wx_alerts[arg.to_sym] ||= Wunderground::WXAlert.new("http://api.wunderground.com/auto/wui/geo/AlertsXML/index.txt?query=#{url_arg}")
            @wx_alerts[arg.to_sym].update!
            if @wx_alerts[arg.to_sym].alerts then
              @wx_alerts[arg.to_sym].alerts.each do |a|
                msg dest, "A \"#{a[:description]}\" for #{arg} expires #{a[:expires]}. (http://www.wund.com/cgi-bin/findweather/getForecast?query=#{url_arg}##{a[:type]})"
              end
              msg dest, "send \"!wx unwatch #{cookie}\" to remove.  (Repeats every #{@watcher_interval} seconds while alerts are active)"
            else
              puts "No alerts (auto) for #{arg}" 
            end
          end
        end
      end
    end
    
  end
  # TODO: Persist watchers across sessions
  def watchers
    if (nick =~ /^#{BOT_CONFIG[:owner_nick]}$/i) then
      @wx_watch.each { |w| msg nick, w.join("::") }
      msg nick, "#{@watcher_interval} second interval"
    end
  end
  
  def interval
    args.strip!
    if (nick =~ /^#{BOT_CONFIG[:owner_nick]}$/i) then
      if args == "" then
        automsg "Interval set at #{@watcher_interval} seconds"
      elsif args =~ /[0-9]+/ then
        if args.to_i == 0 then
        else
          @watcher_interval = args.to_i
          automsg "Interval set to #{args}"
        end
      else
        automsg "!wx interval [int]"
      end
    end
  end
  
  def watch
    cookie = Base64.encode64(args + (channel || nick))[0..5]
    @wx_watch << [ args, channel || nick, cookie ]
    automsg "Added #{args} WX query:  \"!wx unwatch #{cookie}\"  to remove."
  end
  
  # user requests unwatching with cookie
  def unwatch
    args.strip!
    @wx_watch.delete_if { |s| s[2] == args }
  end
  
  context :auto
  # Heavy alias : I don't know for sure that using Alias would trigger the 
  # method_added handler, so I'm wrapping instead.
  def alert
    alerts
  end
  
  
  
  
  def alerts
    @mutex.synchronize do
      arg = args
      url_arg = URI.escape(arg.to_s.chomp.strip)
      @wx_alerts[arg.to_sym] ||= Wunderground::WXAlert.new("http://api.wunderground.com/auto/wui/geo/AlertsXML/index.txt?query=#{url_arg}")
      @wx_alerts[arg.to_sym].update!
      if @wx_alerts[arg.to_sym].alerts then
        @wx_alerts[arg.to_sym].alerts.each do |a|
          automsg "A \"#{a[:description]}\" for #{arg} expires #{a[:expires]}. (http://www.wund.com/cgi-bin/findweather/getForecast?query=#{url_arg}##{a[:type]})"
        end
      else
        automsg "No alerts for #{arg}" 
      end
    end
  end
  
  def bulletin
    @mutex.synchronize do
      arg = args
      url_arg = URI.escape(arg.to_s.chomp.strip)
      @wx_alerts[arg.to_sym] ||= Wunderground::WXAlert.new("http://api.wunderground.com/auto/wui/geo/AlertsXML/index.txt?query=#{url_arg}")
      @wx_alerts[arg.to_sym].update!
      if @wx_alerts[arg.to_sym].alerts then
        automsg "WX Bulletin for U.S. zipcode #{arg} has #{@wx_alerts[arg.to_sym].alerts.size} alerts:"
        @wx_alerts[arg.to_sym].alerts.each do |a|     
          automsg "Description: #{a[:description]}"
          automsg "Effective: #{a[:date]}"
          automsg "Expires: #{a[:expires]}"
          a[:message].lines.each { |line| automsg "Bulletin: #{line}" }
        end  
        automsg "(http://www.wund.com/cgi-bin/findweather/getForecast?query=#{url_arg})}"
      else
        automsg "No alerts for #{arg}" 
      end
    end
  end
  
  context :helper
  def publish_alerts(to,cmd,arg)
    url_arg = URI.escape(arg.to_s.chomp.strip)
    
    case
    when (cmd =~ /alerts?/i)
      @wx_alerts[arg.to_sym] ||= Wunderground::WXAlert.new("http://api.wunderground.com/auto/wui/geo/AlertsXML/index.txt?query=#{url_arg}")
      @wx_alerts[arg.to_sym].update!
      if @wx_alerts[arg.to_sym].alerts then
        @wx_alerts[arg.to_sym].alerts.each do |a|
          msg to, "A \"#{a[:description]}\" for #{arg} expires #{a[:expires]}. (http://www.wund.com/cgi-bin/findweather/getForecast?query=#{url_arg}##{a[:type]})}"
        end
      else
        msg to, "No alerts for #{arg}" 
      end
    when (cmd =~ /bulletin/i)
      @wx_alerts[arg.to_sym] ||= Wunderground::WXAlert.new("http://api.wunderground.com/auto/wui/geo/AlertsXML/index.txt?query=#{url_arg}")
      @wx_alerts[arg.to_sym].update!
      if @wx_alerts[arg.to_sym].alerts then
        msg to, "WX Bulletin for U.S. zipcode #{arg} has #{@wx_alerts[arg.to_sym].alerts.size} alerts:"
        @wx_alerts[arg.to_sym].alerts.each do |a|     
          msg to, "Description: #{a[:description]}"
          msg to, "Effective: #{a[:date]}"
          msg to, "Expires: #{a[:expires]}"
          a[:message].lines.each { |line| msg to, "Bulletin: #{line}" }
        end  
        msg to, "(http://www.wund.com/cgi-bin/findweather/getForecast?query=#{url_arg})}"
      else
        msg to, "No alerts for #{arg}" 
      end
    else
      # Output help
      puts "Implement help!"
    end #case
  end  
end
