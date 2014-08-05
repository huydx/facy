module Facy
  module Output
    def output
      stream_print_queue.reverse!
      while !stream_print_queue.empty?
        post = stream_print_queue.pop
        pretty_print(post) unless stream_printed.include? post["post_id"]
      end
    end

    def pretty_print(post)
      stream_printed.add post["post_id"]
      puts <<-STREAM_ITEM
        #{user_id_cache_store[post["actor_id"]]} 
          message: #{strip(post["message"])}
      STREAM_ITEM
    end

    def strip(text)
      text
    end
  end

  extend Output
end
