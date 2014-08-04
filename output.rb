module Facy
  module Output
    def output
      stream_print_queue.each do |post| 
        pretty_print(post) unless stream_printed.include? post["post_id"]
      end
    end

    def pretty_print(post)
      stream_printed.add post["post_id"]
      puts <<-STREAM_ITEM
        #{user_id_cache_store.read(post["actor_id"])} 
          message: #{strip(post["message"])}
      STREAM_ITEM
    end

    def strip(text)
      text
    end
  end

  extend Output
end
