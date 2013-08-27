require 'cora'
require 'siri_objects'
require 'pp'
require 'open-uri'
require 'nokogiri'

class SiriProxy::Plugin::InsteonBulbs < SiriProxy::Plugin
  def initialize(config)
      appname = "SiriProxy-InsteonBulbs"
      @host = config["insteon_hub_ip"]
      @port = config["insteon_hub_port"]
      @allbulbs = nil
      rooms = File.expand_path('~/.siriproxy/house_config.yml')
      if (File::exists?( rooms ))
          @roomlist = YAML.load_file(rooms)
      end
      @roomlist.each { |room|
          if (room[0] != "house")
            if (@allbulbs == nil)
                @allbulbs = @roomlist[room[0]]["lights"]["bulbs"]
            else
                @allbulbs = @allbulbs + " " + @roomlist[room[0]]["lights"]["bulbs"]
            end
          end
      }
  end
    
  def percentToHex(percent)
      if (percent.to_i >= 100)
          return "0F11FF"
      end
      if (percent.to_i <= 0)
          return "0F13FF"
      end
      multiplier = 2.5
      result = ((100 - percent.to_i) * multiplier).ceil
      result = 255 - result
      result = "%02X" % result
      return "0F11#{result}"
  end
    
  def controlLights(percent,location)
      if (location == "all")
          bulbs = @allbulbs.split(" ")
      else
          bulbs = @roomlist[location]["lights"]["bulbs"].split(" ")
      end
      bulbs.each { |bulb|
          endstring = percentToHex(percent)
          #puts "http://#{@host}:#{@port}/3?0262#{bulb}#{endstring}=I=3"
          Nokogiri::HTML(open("http://#{@host}:#{@port}/1?XB=M=1"))
          Nokogiri::HTML(open("http://#{@host}:#{@port}/3?0262#{bulb}#{endstring}=I=3"))
       }
  end
    
  def find_active_room(macaddress)
    location = ""
    filename = macaddress.gsub(":","")
    filename = filename.gsub("\n","")
    filename = "#{filename}.siriloc"
    if (!File.exists?("#{filename}"))
        return false
    else
        File.open(filename).read.split("\n").each do |line|
            location = line
        end
        return location
    end
   end
    
   def has_lights(location)
     if(location == "all")
         return true
     end
     if(@roomlist[location]["lights"] == nil)
        return false
     else
        return true
     end
   end
    
    listen_for /^(?:How do I|How can I|What can I|Do I|How I|How are you|Show the commands for|Show the commands to|What are the commands for) (?:control |do with |controlling |do at )?(?:the)? (?:lights|light)/i do
        say "Here are the commands for controlling the lights:\n\nTurn off the lights in the room your are in:\n  \"Turn off the lights\"\n\nTurn on the lights in the room your are in:\n  \"Turn on the lights\"\n\nTurn off the lights in a specific room:\n  \"Turn off the lights in the living room\"\n\nSet lights to a percentage in the room you are in:\n  \"Set lights to 50 percent\"\n\nSet lights to a percentage in a specific room:\n  \"Set lights to 50 percent in the living room\"\n\nTurn off the lights in the entire house/apartment:\n  \"Turn off the lights everywhere\"\n\nTurn on the lights in the entire house/apartment:\n  \"Turn on the lights everywhere\"\n\nSet lights to a percentage in the entire house/apartment:\n  \"Set lights to 50 percent everywhere:\"",spoken: "Here are the commands for controlling the lights"
        request_completed
    end

    listen_for /^(?:[S|s]et light|[S|s]et lights|[S|s]et Satellites|[S|s]et like|[S|s]et likes|[S|s]et the light|[S|s]et the lights|[S|s]et the Satellites|[S|s]et the like|[S|s]et the likes|Satellites) to ([0-9]+)%(?:(?: in the| of the| in my) )?(.*)?/i do |percent,roomname|
    if (roomname == "leaving")
        roomname = "living room"
    end
    if (roomname == ("house") || roomname == (" house") || roomname == (" whole house") || roomname == ("whole house") || roomname == (" everywhere") || roomname == ("Holthaus")|| roomname == ("apartment")|| roomname == (" apartment") || roomname == ("whole apartment")|| roomname == (" whole apartment"))
        case roomname
            when 'house',' house', ' whole house', 'whole house', ' Holthaus'
                housename = "in the house"
            when ' everywhere'
                housename = "everywhere"
            when 'apartment', ' apartment', 'whole apartment', ' whole apartment'
                housename = "in the apartment"
        end
        currentLoc = "all"
    end
    if (roomname == "")
        deviceMAC = %x[arp -an | grep '(#{self.manager.device_ip})' | cut -d\\  -f4]
        currentLoc = find_active_room(deviceMAC)
        if (currentLoc == false)
            say "I don't know where you are.  Please tell me what room you are in."
        end
    else
        if (currentLoc != "all")
            currentLoc = roomname
        end
    end
    if (currentLoc == "all" || @roomlist.has_key?(currentLoc))
        if (has_lights(currentLoc) == true)
            controlLights(percent,currentLoc)
            if (currentLoc == "all")
                say "Lights set to #{percent}% #{housename}"
            else
                say "Lights set to #{percent}% in the #{currentLoc}"
            end
        else
            say "There are no lights in the #{currentLoc}"
        end
    else
        say "There is no room defined called \"#{currentLoc}\""
    end
    request_completed
  end

listen_for /(?:Turn )?( the | off all the | on all the | off all | on all | on | off | on the | off the )?[L|l|F|l]ight(?:s)?( on| off)?(?: in the | in my )?(.*)?/i do |stateone,statetwo,roomname|
    if (roomname == "leaving")
        roomname = "living room"
    end
    if (roomname == ("house") || roomname == (" house") || roomname == (" whole house") || roomname == ("whole house") || roomname == (" everywhere") || roomname == ("Holthaus")|| roomname == ("apartment")|| roomname == (" apartment") || roomname == ("whole apartment")|| roomname == (" whole apartment"))
        case roomname
            when 'house',' house', ' whole house', 'whole house', ' Holthaus'
                housename = "in the house"
            when ' everywhere'
                housename = "everywhere"
            when 'apartment', ' apartment', 'whole apartment', ' whole apartment'
                housename = "in the apartment"
        end
        currentLoc = "all"
    end
    if (roomname == "")
        deviceMAC = %x[arp -an | grep '(#{self.manager.device_ip})' | cut -d\\  -f4]
        currentLoc = find_active_room(deviceMAC)
        if (currentLoc == false)
            say "I don't know where you are.  Please tell me what room you are in."
        end
    else
        if (currentLoc != "all")
              currentLoc = roomname
        end
    end
    if (currentLoc == "all" || @roomlist.has_key?(currentLoc))
        if (has_lights(currentLoc) == true)
            if (stateone == " off the " || statetwo == " off" || stateone == " off " || stateone == " off all the " || stateone == " off all ")
                controlLights(0,currentLoc)
                onoff = "off"
            elsif (statetwo == nil || stateone == " on the " || statetwo == " on" || stateone == " on all the " || stateone == " on all ")
                controlLights(100,currentLoc)
                onoff = "on"
            end
            
            if (currentLoc == "all")
                say "Lights turned #{onoff} #{housename}"
            else
                say "Lights turned #{onoff} in the #{currentLoc}"
            end
          else
            say "There are no lights in the #{currentLoc}"
          end
      else
          say "There is no room defined called \"#{currentLoc}\""
      end
      request_completed
  end  
end
