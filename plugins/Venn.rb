# encoding: utf-8
class Venn < PluginBase
  description "Venn Diagrams of room membership"
  token           :venn
  context         :auto
  default_command :chart
  
  def help
    msg nick, "Welcome to the Venn plugin for RubOt.  The Venn plugin allows you"
    msg nick, "to create a venn diagram of the users in 2 or 3 rooms.  The chart"
    msg nick, "is presented to you as a link to a charting service hosted by Google"
    msg nick, " "
    msg nick, "Usage:  !venn <#room1> <#room2> [#optional room3]"
    msg nick, "        !venn help"
  end
  
  def chart
    if (@venning ||= false) then
      automsg "I'm busy, try again in about 10 seconds!"
      puts "Turning down VENN request from #{nick} (busy)"
    else 
      #set querier to channel or nick, if private
      @querier = channel || nick
      
      puts "Venn for #{nick}: #{message}" 
      # parse command for proper format
      message.strip!
      # reset the hash of sets (arrays), for user names
      @userrooms = {}
      @remaining_room_queries = []
      @joined_rooms = []  # Rooms that had to be joined for this chart
      
      #build room list and join rooms
      message.split("\s").each do |room|
        if (room =~ /#[a-z0-9-]+/i)
          join room
          @userrooms[room.upcase.to_sym] = []
        end
      end
      
      # Validate List
      if ((@userrooms.keys.count < 2) or (@userrooms.keys.count > 3)) then
        msg @querier, "Only 2 and 3 circle venns are supported.  Specify exactly two or three rooms."
        @userrooms = {}
      else
        @remaining_room_queries = @userrooms.keys
        @userrooms.keys.each { |room| raw "who #{room} %cu" }
      end
    end
  end
  
  context :helper
  def _handle_354
    @userrooms[@bot.mesg.params[1].upcase.to_sym] << @bot.mesg.params[2] if @bot.mesg.params[2] !~ /#{BOT_CONFIG[:bot_nick]}/i
  end
  
  def _handle_366
    # a 366 received means I had to join the room, no 366 means I was already in the room
    @joined_rooms ||= []
    # Add the room I had to join to the list.
    @joined_rooms <<  @bot.mesg.params[1].upcase.to_sym
    puts "completed join to #{@bot.mesg.params[1]}"
  end
  
  def _handle_315
    puts "Finished tally for #{@bot.mesg.params[1]}"
    @remaining_room_queries.delete(@bot.mesg.params[1].upcase.to_sym)
    
    # Part any rooms I had to join
    if (@joined_rooms.include?(@bot.mesg.params[1].upcase.to_sym)) then
          part(@bot.mesg.params[1].upcase.to_sym)
          puts("leaving #{@bot.mesg.params[1].upcase} - done peeking")
    end

    if (@remaining_room_queries.empty?) then
      # Now let's construct the arguments for google charts api
      # We need 7 values according to "http://code.google.com/apis/chart/docs/gallery/venn_charts.html"
      rooms = @userrooms.keys
      three_rooms = (@userrooms.count == 3)
      data = []
      data[0] = @userrooms[rooms[0]].count
      data[1] = @userrooms[rooms[1]].count
      data[2] = 0
      data[2] = @userrooms[rooms[2]].count if three_rooms

      intersection = @userrooms[rooms[0]] & @userrooms[rooms[1]] unless three_rooms
      data[3] = (@userrooms[rooms[0]] & @userrooms[rooms[1]]).count


      if (three_rooms) then
        data[4] = (@userrooms[rooms[0]] & @userrooms[rooms[2]]).count
        data[5] = (@userrooms[rooms[1]] & @userrooms[rooms[2]]).count
        data[6] = (@userrooms[rooms[0]] & @userrooms[rooms[1]] & @userrooms[rooms[2]]).count
        intersection = @userrooms[rooms[0]] & @userrooms[rooms[1]] & @userrooms[rooms[2]]
      end
      labels = rooms.join("|").gsub("#","")

      # Shrink data
      data.collect! { |x| x/10.0 }

      msg @querier, "http://chart.apis.google.com/chart?cht=v&chs=500x500&chd=t:#{data.join(",")}&chdl=#{labels}"
      msg @querier, "set intersection [#{intersection.join(", ")}]"
      msg @querier, "membership:"
      @userrooms.each_pair { |room,members| msg @querier, "            #{room.to_s} has #{members.count}"}
      @venning = false
    else
      puts "Still need to visit #{@remaining_room_queries.inspect}"
    end
  end
  
  def register_commands  # override register commands to use special commands
    super

    m = self.class.meth_wrap_proc(self.method(:_handle_354))
    @bot.on :"354", //, &m
    
    m = self.class.meth_wrap_proc(self.method(:_handle_366))
    @bot.on :"366", //, &m

    m = self.class.meth_wrap_proc(self.method(:_handle_315))
    #Handle an end of query message
    @bot.on :"315", //, &m
  end
end