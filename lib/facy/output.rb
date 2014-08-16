module Facy
  module Output
    def periodic_output
      return if (items = not_yet_print_items).empty?
      new_line
      items.each {|item| instant_output(item)}
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

    def stop_animation
      @stop_animation ||= true
    end

    def error(text)
      puts text
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
      info = item.info.to_s.capitalize.colorize(38,5,118).strip
      type = item.data.type.colorize(0,34)
      uname = item.data.user
      uname = uname.colorize(username_color(uname))
      content = item.data.content.colorize(0,55)

      puts "[#{code}][#{info}] <#{type}> #{uname} #{content}"
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
      new_line
      info = item.info.to_s.capitalize.colorize(0,31) 
      content = item.content
      puts "[#{info}] #{content}"
      clear_line
    end

    print_register :error do |item|
      new_line
      info = "Error".colorize(0,31)
      puts "[#{info}] #{item.content}"
      clear
    end
  end

  extend Output
end
