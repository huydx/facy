# coding: utf-8

module Facy
  module Output
    def periodic_output
      return if (items = not_yet_print_items).empty?
      new_line
      #items.each {|item| instant_output(item)}
      items.each do |item|
          instant_output(item)
      end
      clear_line
    end

    def not_yet_print_items
      items = []
      while !stream_print_queue.empty?
        post = stream_print_queue.pop
        items << post unless printed_item.include? post.id
      end

      while !notification_print_queue.empty?
        notify = notification_print_queue.pop
        items << notify unless printed_item.include? notify.id
      end
      return items
    end

    def instant_output(item)
      sync { printed_item << item.id if item.id }
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

    def stop_animation
      @stop_animation ||= true
    end

    def error(text)
      instant_output(Item.new(info: :error, content: text))
    end

    def new_line
      puts ''
    end

    def clear_line
      Readline.refresh_line
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

    def post_code(item)
      post_id = item.id

      return post_code_map[post_id] if post_code_map[post_id]
      post_code_table_load if post_code_table.empty?
      code = post_code_table.pop

      post_code_reverse_map[code] = item
      post_code_map[post_id] = code

      return code 
    end

    def post_code_table
      @post_code_table ||= []
    end

    def post_code_map
      @post_code_map ||= {}
    end

    def post_code_reverse_map
      @post_code_reverse_map ||= {}
    end

    def post_code_table_load
      max_length = 3
      _post_code_table_loop('$', max_length)
      post_code_table.sort!
    end

    def _post_code_table_loop(prefix, max_length)
      post_code_table << prefix if prefix.length > 0
      if prefix.length < max_length
        ('a'..'z').each do |char|
          _post_code_table_loop(prefix + char, max_length)
        end
      end
    end
  end
  
  init do
    print_registers.clear
    username_color_table_load
    post_code_table_load

    print_register :feed do |item|
      code = post_code(item).colorize(38,5,8).strip
      info = "♡  #{item.info.to_s.capitalize}".colorize(38,5,118).strip
      type = item.data.type.colorize(38,5,238)
      uname = item.data.user
      like_count = item.data.like_count.to_s.colorize(36,48,5,0)
      comment_count = item.data.comment_count.to_s.colorize(36,48,5,0)
      share_count = item.data.share_count.to_s.colorize(36,48,5,0)
      uname = uname.colorize(username_color(uname))
      content = item.data.content.colorize(0,55)
      date = item.data.date
      if config[:utilize_emojis]
        video_indicator=""
        picture_indicator=""
        if item.data.video.present?
          video_indicator="🎞"
        end
        if item.data.picture.present?
          picture_indicator="🖼"
        end

        animated_gif_indicator=""
        if (item.data.video.include? ".gif")
          animated_gif_indicator="🔁"
        end   
        
        react = item.data.react_scores
        react = react.gsub(";", "")
        react = react.sub(/[0-9.]+.? Like/, "")
        react = react.sub(/([0-9.]+.?) Haha/, "😃 :\\1 ")
        react = react.sub(/([0-9.]+.?) Sad/, "😢 :\\1 ")
        react = react.sub(/([0-9.]+.?) Angry/, "😡 :\\1 ")
        react = react.sub(/([0-9.]+.?) Wow/, "😮 :\\1 ")
        react = react.sub(/([0-9.]+.?) Love/, "❤ :\\1 ")
        puts "[#{code}][#{info}] #{uname} #{content}  {#{type}} #{video_indicator}  #{picture_indicator} #{animated_gif_indicator} 👍 :#{like_count} C:#{comment_count} S:#{share_count} #{react}"
      else
        react = item.data.react_scores
        react = react.gsub(";", "")
        react = react.sub(/[0-9.]+.? Like/, "")
        react = react.sub(/([0-9.]+.?) Haha/, "H:\\1 ")
        react = react.sub(/([0-9.]+.?) Sad/, "S:\\1 ")
        react = react.sub(/([0-9.]+.?) Angry/, "A:\\1 ")
        react = react.sub(/([0-9.]+.?) Wow/, "W:\\1 ")
        react = react.sub(/([0-9.]+.?) Love/, "L️:\\1 ")
        puts "[#{code}][#{info}] #{uname} #{content}  {#{type}} L:#{like_count} C:#{comment_count} S:#{share_count} #{react}"
      end
    end
    
    print_register :notification do |item|
      code = post_code(item).colorize(38,5,8).strip
      emoji=""
      if config[:utilize_emojis]
        case item.data.emoji
        when "love"
          emoji="❤️"
        when "like"
          emoji="👍"
        when "haha"
          emoji="😄"
        when "wow"
          emoji="😮"
        when "sad"
          emoji="😢"
        when "angry"
          emoji="😡"
        when "wrench"
          emoji="🔧"
        when "calendar"
          emoji="📅"
        when "commented"
          emoji="💬"
        when "facebook"
          emoji="\e[15;48;5;27m f \e[0m"
        when "page_new_message"
          emoji="🚩"
        when "bug"
          emoji="🐞" #dunno i never seen the image
        when "bookmarked"
          emoji="📑"
        when "photo"
          emoji="🖼"
        when "star"
          emoji="⭐"
        when "unknown"
          emoji="❓"
        else
          emoji="❓"
        end
      end
      
      info = "☢ #{item.info.to_s.capitalize}".colorize(0,31) 
      uname = item.data.user
      uname = uname.colorize(username_color(uname))
      content = item.data.content.colorize(0,55) 

      puts "[#{code}][#{info}] #{emoji} #{uname} #{content}"
    end

    print_register :info do |item|
      new_line
      info = item.info.to_s.capitalize.colorize(0,31) 
      content = item.content
      puts "[#{info}] #{content}"
    end

    print_register :error do |item|
      new_line
      info = "Error".colorize(0,31)
      puts "[#{info}] #{item.content}"
    end

    print_register :help do |item|
      puts item.content
      puts "example: #{item.extra}" if item.extra
      puts "aliasing: #{item.alias_cmds}" if item.alias_cmds
    end

    print_register :comment do |item|
      puts "  #{item.from} => #{item.message}"
    end

    print_register :like do |item|
      puts "  ♥ #{item.from}"
    end

    print_register :mails do
      new_line
      mails = mailbox_cache
      count = 0
      mails.each do |m|
        from = m["to"]["data"].first["name"]
        to = m["to"]["data"].last["name"]
        actor = [from, to].keep_if{|m| m != me["name"]}.first.colorize(33)
        first_message = m["comments"]["data"].last["message"].short.colorize(37)
        
        puts "  {#{count}} from: #{actor} [#{first_message}]"
        count += 1
      end
      clear_line
    end

    print_register :mail do |item|
      new_line
      num = item.content.messagenum
      comments = item.content.mail["comments"]["data"][-num, num]

      comments.each do |comment|
        created = DateTime.parse(comment["created_time"])
        message = comment["message"]
        puts " #{created.strftime('%m/%d %H:%M').colorize(90)} #{message}"
      end
    end
  end

  extend Output
end
