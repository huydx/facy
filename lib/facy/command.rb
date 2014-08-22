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
      error e
      log(:error, e.message)
      log(:error, e.backtrace)
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
          content: "post '#{text}' has been posted to your wall")
         ) if ret["id"]
      }
    end
    help :post, 'post to your own wall', ':post [content]'

    command :like do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]
      post_id = item.id if item.is_a?(Item)
      async { 
        ret = facebook_like(post_id) 
        instant_output(Item.new(info: :info, content: "like success")) if ret
      }
    end
    help :like, 'like a post', ':like [code]'

    command :exit do 
      stop_process  
    end
    help :exit, 'quit facy', ":exit"

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
    help :open, 'open a post in browser', ':open [code]'

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
    help :comment, 'comment to a post,', ':comment [code] [content]'

    command :seen do |notif_code|
      notif_code = "$#{notif_code}"
      item = post_code_reverse_map[notif_code]
      async {
        ret = facebook_set_seen(item.id)
        instant_output(Item.new(info: :info, content: 'unseen success')) if ret
      }
    end
    help :seen, "set a notification to seen", ":seen [code]"

    command :view_raw do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]

      print JSON.pretty_generate(item.raw)
      puts "" 
    end
    help :view_raw, "view raw json output of a post", ":view_raw [post_code]"

    command :view_img do |post_code|
      if config[:enable_img_view]
        post_code = "$#{post_code}"
        item = post_code_reverse_map[post_code]
        
        if item.data.picture
          view_img(item.data.picture)
        else
          instant_output(Item.new(info: :error, content: "this post has no image link"))
        end
      else
        instant_output(Item.new(info: :error, content: "use facy -enable_img_view to enable image viewer"))
      end
    end
    help :view_img, "view an image as ascii art", ":view_img [code]"

    command :view_comments do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]
      comments = item.data.comments

      unless comments.empty?
        comments.each do |cm|
          instant_output(Item.new(info: :comment, from: cm["from"]["name"], message: cm["message"]))
        end
      end
    end
    help :view_comments, "view comments from a post", ":view_comments [code]"

    command :view_likes do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]
      likes = item.data.likes
      unless likes.empty?
        likes.each do |lk|
          instant_output(Item.new(info: :like, from: lk["name"]))
        end
      end
    end
    help :view_likes, "view likes detail from a post", ":view_likes [code]"
    
    command :dump_log do
      if config[:debug_log]
        dump_log
        instant_output(Item.new(info: :info, content: "dump log success to #{log_file}"))
      else
        instant_output(Item.new(
          info: :info, 
          content: "you need to start $facy -debug option to enable log"
        ))
      end
    end
    help :dump_log, "dump debug log to file", ":dump_log"

    command :reconfig do
      begin
        FileUtils.rm(config_file)
        FileUtils.rm(session_file)
        instant_output(Item.new(info: :info, content: "restart facy to reconfig"))
        stop_process
      rescue Exception => e
        error e.message
      end
    end
    help :reconfig, "reconfig app_id, app_secret access token", ":reconfig"

    command :commands do
      helps.each do |help|
        puts ":#{help[:target].to_s.colorize(38,5,8)} #{help[:usage]}"
      end
    end
    help :commands, "list all available commands", ":commands"

    command :clear_cache do
      sync { 
        printed_item.clear
        #TODO clear also code table
      }
    end
    help :clear_cache, "clear posts and notification cache and fetch again", ":clear_cache"

    command :mailbox do |target|
      if target 
        threadnum, messagenum = target.split(" ").map(&:to_i)
        mail = mailbox_cache[threadnum]
        instant_output(Item.new(info: :mail, content: {mail: mail, messagenum: messagenum}))
      else
        async {
          mails = facebook_mailbox
          mails.each {|m| mailbox_cache << m} if mails && !mails.empty? 
          instant_output(Item.new(info: :mails))
        }
      end
    end
    help :mailbox, "read mailbox", ":mailbox [mail number]"

    completion_proc = proc {|s| 
      commands
        .map{|c|c[:pattern]}
        .map{|c|":#{c.to_s}"}
        .grep(/^#{Regexp.escape(s)}/)
    }
    Readline.completion_proc = completion_proc
  end
end
