module Facy
  module Output
    def output
      stream_print_queue.reverse!
      while !stream_print_queue.empty?
        post = stream_print_queue.pop
        stream_print(post) unless stream_printed.include? post["post_id"]
      end
    end

    def stream_print(post)
      stream_printed.add post["post_id"]
      uname = user_id_cache_store[post["actor_id"]]
      pmess = strip(post["message"])
      pdate = DateTime.strptime(post["updated_time"].to_s,'%s') 
      puts <<-STREAM_ITEM
 \e[0;34m #{uname} \e[m : #{pmess} #{pdate.strftime("%m/%d %H:%M")}
      STREAM_ITEM
    end

    def strip(text)
      text.truncate(50)
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
