module Facy
  module Output
    def output
      while !stream_print_queue.empty?
        post = stream_print_queue.pop
        stream_print(post) unless stream_printed.include? post["id"]
      end
      while !notification_print_queue.empty?
        notify = notification_print_queue.pop
        notifications_print(notify) unless notifications_printed.include? notify["id"]
      end
    end

    def stream_print(post)
      stream_printed.add post["id"]
      uname   = post["from"]["name"]
      message = strip(post["message"])
      link    = post["link"]
      time    = Date.parse(post["created_time"])
      puts <<-STREAM_ITEM
\e[0;34m #{uname} \e[m : #{message} \e[0;34m #{link}\e[m #{time.strftime("%m/%d %H:%M")}
      STREAM_ITEM
    end

    def notifications_print(notify)

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

  extend Output
end
