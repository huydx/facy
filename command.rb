module Facy
  module Command
    def commands
      @commands ||= []
    end

    def command(pattern, options={}, &block)
      commands << {pattern: pattern, block: block}
    end

    def execute(text)
      rule, target = match_single_command(text) || match_target_command(text)
      commands.each do |c|
        if rule.to_s == c[:pattern].to_s.split(":").first
          c[:block].call(target)
          return
        end
      end
    rescue Exception => e
      error e.backtrace
    end

    def match_single_command(text)
      text =~ /^:(\S*) (.+)$/
      return [$1, $2] if $1 && $2
      return nil
    end

    def match_target_command(text)
      text =~ /^:(\S*)$/
      return $1
    end
  end

  extend Command

  init do
    commands.clear
    command :post do |text|
      async { 
        ret = facebook_post(text) 
        instant_output(Item.new(
          info: :info, 
          message: "post #{ret["id"]} has been posted to your wall")
         ) if ret["id"]
      }
    end

    command :like do |post_code|
      item = post_code_reverse_map[post_code]
      post_id = item.id if item.is_a?(Item)
      async { 
        ret = facebook_like(post_id) 
        instant_output(Item.new(info: :info, content: "like success")) if ret
      }
    end

    command :exit do 
      stop_process  
    end

    command :open do |post_code|
      post_code = post_code.split("$")[1]
      item = post_code_reverse_map[post_code]
      link = item.data.link if item.is_a?(Item)
      if link
        browse(link)
      else
        async { instant_output(Item.new(info: :error, content: "sorry this post can not be openned")) }
      end
    end

    comp_proc = proc {|s| 
      commands
        .map{|c|c[:pattern]}
        .map{|c|":#{c.to_s}"}
        .grep(/^#{Regexp.escape(s)}/)
    }
    Readline.completion_proc = comp_proc
  end
end
