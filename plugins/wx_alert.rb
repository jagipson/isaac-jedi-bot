#!/usr/bin/env ruby
require 'rexml/document'
require 'rexml/xpath'

module Wunderground
  
  AlertData = Struct.new(:type, :description, :date, :expires, :message, :phenomena, :significance)

  # Implement Weather Alerts using Wundergrounds API Documented \
  # here: http://wiki.wunderground.com/index.php/API_-_XML
  # Using unversioned API dated 2010-03-01
  class WXAlert
    attr_reader :raw # raw data for troubleshooting, should never need to be called  
    def initialize(alert_query_url, ttl_seconds = 600.0)
      # Initialize data associated w/ alerts
      @data = nil # nil or Array of Alert_Data
      @raw = nil
    
      # init administrative members
      @ttl = ttl_seconds
      @last_fetch_time = nil
      @url = alert_query_url
      return self
    end
  
    # determine if the internal cache is stale, or has never been loaded
    def stale? 
      return true if @last_fetch_time.nil?
      return (Time.now >= (@last_fetch_time + @ttl))
    end
  
    # Update the internal data by fetching from the web
    # params { :force => true|false # Whether to force reloading from web, or rely on cache for recent data
    # }
    def update!(params={:force => false})
      if (params[:force] or self.stale?) then
      
        # FIX: using curl, because it's cheap and easy.  Switch to HTTP module if needing
        # to reduce system dependancies to Ruby Only libs.
        exec_command = "curl #{@url}"
        puts "Will run: #{exec_command}"
        @raw = `#{exec_command}`
        @last_fetch_time = Time.now
        @data = nil
        
        # Also, lets assume there's XML in there.
        # For format, consult Wunderground API
        rex = REXML::Document.new(@raw)
        rex.elements.each("//AlertItem") do |alertml|
          alert_data = AlertData.new
          alert_data.members.each { |member| alert_data[member] = REXML::XPath.first(alertml, member.to_s).text if REXML::XPath.first(alertml, member.to_s) }
          @data ||= [] #initialize @data if nil
          @data << alert_data
        end # end do each
      end #end if
      return @data
    end #end update
  
    def alerts
      self.update!
      return @data if (@data and not self.stale?)
      return nil
    end
  
  end #class
end # module