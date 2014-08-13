module Facy
  module Output
    def periodic_output
      while !stream_print_queue.empty?
        post = stream_print_queue.pop
        instant_output(post) unless printed_item.include? post.id
      end

      while !notification_print_queue.empty?
        notify = notification_print_queue.pop
        instant_output(notify) unless printed_item.include? notify.id
      end
    end

    def instant_output(item)
      printed_item << item.id if item.id
      info = item.info
      print_registers.each do |pattern|
        if info == pattern[:name]
          pattern[:block].call(item)
        end
      end
    rescue
    end

    def print_registers
      @print_registers ||= []
    end

    def print_register(item_name, &block)
      print_registers << {name: item_name, block: block}
    end

    def strip(text)
      text.truncate(50) if text
    end

    def loading_animation
      loading_text = "Fetching"
      while true 
        Thread.stop if stop_animation
        sleep 0.1
        print "#{loading_text} \\" + "\r"
        sleep 0.1
        print "#{loading_text} |" + "\r"
        sleep 0.1
        print "#{loading_text} /" + "\r"
        sleep 0.1
        print "#{loading_text} -" + "\r"
      end
    end

    def stop_animation
      @stop_animation ||= true
    end

    def error(text)
      puts text
    end

    def username_color_map
      @username_color_map ||= {}
    end

    def username_color_table
      @username_color_table ||= []
    end

    def username_color_table_load
      max_range = 256 
      step      = 9
      start     = current = 1
      (1..max_range).each do |col|
        username_color_table << [38,5,current]
        current = current + step
        current = current % max_range if current > max_range
      end
    end 

    def username_color(uname)
      return username_color_map[uname] if username_color_map[uname]
      username_color_table_load if username_color_table.empty?
      return (username_color_map[uname] = username_color_table.pop)
    end
  end
  
  init do
    print_registers.clear
    username_color_table_load

    print_register :feed do |item|
      info = item.info.to_s.capitalize.colorize(35,8,118) 
      type = item.data.type.colorize(0,34)
      uname = item.data.user
      uname = uname.colorize(username_color(uname))
      content = item.data.content.colorize(0,55)

      puts "[#{info}] #{uname} #{content}"
    end
    
    print_register :notification do |item|
      info = item.info.to_s.capitalize.colorize(0,31) 
      uname = item.data.user
      uname = uname.colorize(username_color(uname))
      content = item.data.content.colorize(0,55) 

      puts "[#{info}] #{uname} #{content}"
    end

    print_register :link do |item|
      
    end

    print_register :photo do |item|

    end

    print_register :info do |item|
      info = item.info.to_s.capitalize.colorize(0,31) 
      content = item.content
      puts "[#{info}] #{content}"
    end
  end

  extend Output
end
