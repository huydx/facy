module Facy
  module Output
    def periodic_output
      while !stream_print_queue.empty?
        post = stream_print_queue.pop
        instant_output(post) unless stream_printed.include? post.id
      end

      while !notification_print_queue.empty?
        notify = notification_print_queue.pop
        instant_output(notify) unless notification_printed.include? notify.id
      end
    end

    def instant_output(item)
      stream_printed << item.id
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
  end
  
  init do
    print_registers.clear

    print_register :feed do |item|
      info = item.info.to_s.capitalize.colorize(0,31) 
      type = item.data.type.colorize(0,34)
      user = item.data.user.colorize(0,41)
      content = item.data.content.colorize(0,55)

      puts "[#{info}] #{user} #{content}"
    end
    
    print_register :notification do |item|
      info = item.info.to_s.capitalize.colorize(0,31) 
      user = item.data.user.colorize(0,41)
      content = item.data.content.colorize(0,55) 

      puts "[#{info}] #{user} #{content}"
    end

    print_register :link do |item|
      
    end

    print_register :photo do |item|

    end

    
  end

  extend Output
end