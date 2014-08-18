module Facy
  module Command
    def commands
      @commands ||= []
    end

    def command(pattern, options={}, &block)
      commands << {pattern: pattern, block: block}
    end

    def execute(text)
      text.strip!
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

    def match_target_command(text)
      text =~ /^:(\S*) (.+)$/
      return [$1, $2] if $1 && $2
      return nil
    end

    def match_single_command(text)
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
    help :post, 'usage :post [post content] <post to wall>', ':post how a nice day!'

    command :like do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]
      post_id = item.id if item.is_a?(Item)
      async { 
        ret = facebook_like(post_id) 
        instant_output(Item.new(info: :info, content: "like success")) if ret
      }
    end
    help :like, 'usage :like [post_code] <like a post, post_code is a code in the head of each post without $>', ':like za'

    command :exit do 
      stop_process  
    end
    help :exit, 'usage :exit <quit facy>'

    command :open do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]
      link = item.data.link if item.is_a?(Item)
      p link
      if link
        browse(link)
      else
        async { instant_output(Item.new(info: :error, content: "sorry this post can not be openned")) }
      end
    end
    help :open, 'usage :open [post_code] <open a post in browser, post code is a code in the head of each post without $>', ':open za'

    command :comment do |content|
      content = content.split(" ")
      post_code = "$#{content.first}"
      comment = content.tap{|c|c.shift}.join(' ')
      
      item = post_code_reverse_map[post_code]
      post_id = item.id if item.is_a?(Item)

      async {
        ret = facebook_comment(post_id, comment)
        instant_output(Item.new(info: :info, content: 'comment success')) if ret
      }
    end
    help :comment, 'usage :comment [post_code] [comment content] <comment to a post, post code is a code in the head of each post without $>', ':comment za how fun is it!'

    command :seen do |notif_code|
      async {
        ret = facebook_set_seen(notif_code)
        instant_output(Item.new(info: :info, content: 'unseen success')) if ret
      }
    end

    command :view_raw do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]

      print JSON.pretty_generate(item.raw)
      puts "" 
    end
    help :view_raw, "view raw json output of a post", ":view_raw [post_code]"
    
    command :dump_log do
      if config[:debug_log]
        dump_log
        instant_output(Item.new(info: :info, content: "dump log success to #{log_file}"))
      else
        instant_output(Item.new(
          info: :info, 
          content: "you need to start facy with --debug true option to enable log"
        ))
      end
    end
    help :dump_log, "dump debug log to file", ":dump_log"

    completion_proc = proc {|s| 
      commands
        .map{|c|c[:pattern]}
        .map{|c|":#{c.to_s}"}
        .grep(/^#{Regexp.escape(s)}/)
    }
    Readline.completion_proc = completion_proc
  end
end
