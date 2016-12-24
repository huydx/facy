module Facy
  module Command
    def aliasing(origin, with)
      alias_commands[with] = origin
    end

    def alias_commands
      @alias_commands ||= {}
    end

    def commands
      @commands ||= []
    end

    def command(pattern, options={}, &block)
      commands << {pattern: pattern, block: block}
    end

    def execute(text)
      text.strip!
      rule, target = match_single_command(text) || match_target_command(text)
      origin = alias_commands[rule.to_sym] if rule
      rule = origin.nil? ? rule : origin

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
    aliasing :open, :op

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
    aliasing :comment, :cm

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
    aliasing :view_raw, :vr

    command :login do
      config[:fb_email]=""
      config[:fb_password]=""
      if File.exists?("#{config[:fb_cookiejar]}")
        FileUtils.rm("#{config[:fb_cookiejar]}")
      end
      setup_feed_login
    end
    help :login, "delete and update login facebook cookies for both the news feed and for notifications", ":login"

    command :set_notification_pages do |num|
      config[:set_notification_pages] = num.to_i
    end
    help :set_notification_pages, "sets the number of notification pages fetched", ":set_notification_pages"
    aliasing :set_notification_pages, :np

    command :set_news_feed_pages do |num|
      config[:set_news_feed_pages] = num.to_i
    end
    help :set_news_feed_pages, "sets the number of news feed pages fetched", ":set_news_feed_pages"
    aliasing :set_news_feed_pages, :nfp

    command :set_new_notifications_only do |v|
      config[:set_new_notifications_only] = v.to_i
      config[:id_timestamp_last_notifications] = 0;
    end
    
    help :set_unread_notifications_only, "set to 1 to fetch new notifications. set to 0 for all notifications", ":set_new_notifications_only"
    aliasing :set_unread_notifications_only, :nn

    command :set_show_latest_news do |v|
      config[:set_show_latest_news] = v.to_i
      config[:id_timestamp_last_news_feed] = 0;
    end
    help :set_show_latest_news, "set to 1 to fetch new latest news. set to 0 for top stories", ":set_show_latest_news"
    aliasing :set_show_latest_news, :sln

    command :view_img_caca do |post_code, target=:post|
      rmagick = true
      begin
        rmagick = true if require "rmagick"
      rescue
      end

      if config[:enable_img_view] && rmagick
        post_code = "$#{post_code}"
        item = post_code_reverse_map[post_code]

        if target == :comment
          url = item.data.comment_sticker
        else
          url = item.data.picture
        end

        if url
          view_img(url, draw_method: :caca)
        else
          instant_output(Item.new(info: :error, content: "this post has no image link"))
        end
      else
        instant_output(Item.new(info: :error, content: "use facy -enable_img_view to enable image viewer"))
      end
    end
    help :view_img_caca, "view an image as ascii art with libcaca", ":view_img_caca [code]"
    aliasing :view_img_caca, :vic

    command :view_img_termpic do |post_code, target=:post|
      rmagick = true
      begin
        rmagick = true if require "rmagick"
      rescue
      end

      if config[:enable_img_view] && rmagick
        post_code = "$#{post_code}"
        item = post_code_reverse_map[post_code]
        
        if target == :comment
          url = item.data.comment_sticker
        else
          url = item.data.picture
        end

        if url
          view_img(url, draw_method:  :termpic)
        else
          instant_output(Item.new(info: :error, content: "this post has no image link"))
        end
      else
        instant_output(Item.new(info: :error, content: "use facy -enable_img_view to enable image viewer"))
      end
    end
    help :view_img_termpic, "view an image as ascii art with termpic", ":view_img_termpic [code]"
    aliasing :view_img_termpic, :vit
    aliasing :view_img_termpic, :view_img

    command :view_img_ev do |post_code, target=:post|
        post_code = "$#{post_code}"
        item = post_code_reverse_map[post_code]
        
        if target == :comment
			picture = item.data.comment_sticker
        else
			picture = item.data.picture
		end
		
      `#{external_image_viewer} #{picture}`
    end
    help :view_img_ev, "view an image as external viewer", ":view_img_ev [code]"
    aliasing :view_img_ev, :viev

    command :view_movie_caca do |post_code, target=:post|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]

      if target == :comment
        video = item.data.comment_video
      else
        video = item.data.video
      end

      scwd=File.dirname(__FILE__)
      config[:pause_output]=true

      cp="#{config[:session_file_folder]}/mplayercontrol" #control
      cp=File.expand_path("#{cp}") #mplayer wants it expanded
      ip="#{config[:session_file_folder]}/mplayerdata" #data in
      ua="#{config[:user_agent]}"
      height="240" #lower is better for rendering speed
      cookie_file="#{config[:session_file_folder]}/facebook-ns-cookies.txt"
      
      spawn("mkfifo #{cp}",[:err, :out]=>"/dev/null")
      spawn("mkfifo #{ip}",[:err, :out]=>"/dev/null")
      
      puts "please wait buffering... press any key to stop..."
      mplayer_common_args=%q[-msglevel all=-1 -framedrop -noconsolecontrols -slave -cookies -cache 16000 -quiet -vo caca]
      if video.include? "youtube.com" or video.include? "youtu.be"
        ytdl_pid=spawn(%Q[youtube-dl -f "[height<=#{height}]" -q "#{video}" > #{ip}])
        mplayer_pid=spawn({"CACA_DRIVER"=>"ncurses"},%Q[mplayer #{mplayer_common_args} -cookies-file "#{cookie_file}" -user-agent "#{ua}" -input file="#{cp}" "#{ip}"])
      else
        mplayer_pid=spawn({"CACA_DRIVER"=>"ncurses"},%Q[mplayer #{mplayer_common_args} -cookies-file "#{cookie_file}" -user-agent "#{ua}" -input file="#{cp}" "#{video}"])
      end
      while Process.waitpid(mplayer_pid, Process::WNOHANG).nil? do
         begin
           c = STDIN.read_nonblock(1)
           if c.present?
             break
           end
         rescue Errno::EWOULDBLOCK
           retry
         rescue Errno::AGAIN
           retry
         rescue IO::WaitReadable
           IO.select([STDIN])
           retry
         rescue EOFError
           break
         rescue => detail
           print detail.backtrace.join("\n")
         end
      end
      `echo "quit" > #{cp}`
      `stty sane`
      if video.include? "youtube.com" and Process.waitpid(ytdl_pid, Process::WNOHANG).nil?
        Process.kill("INT", ytdl_pid)
      end
      config[:pause_output]=false
    end
    help :view_movie_caca, "view movie as ascii art with libcaca", ":view_movie_caca [code]"
    aliasing :view_movie_caca, :vmc

    command :view_movie_wb do |post_code, target=:post|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]
      
      if target == :comment
		video = item.data.comment_youtube
      else
		video = item.data.video
      end
      
      pid = spawn("#{config[:external_www_browser]} \"#{video}\"")
      Process.detach(pid)
    end
    help :view_movie_wb, "view movie in web browser", ":view_movie_wb [code]"
    aliasing :view_movie_wb, :vmwb

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
    aliasing :view_comments, :vc

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
    aliasing :view_likes, :vl
    
    command :view_spotify_playlist do |post_code|
      post_code = "$#{post_code}"
      item = post_code_reverse_map[post_code]
      link = item.data.link
      
      if link.include? "https://open.spotify.com/user/" and link.include? "/playlist/"
        url = link.gsub(%r{https://open.spotify.com/user/([a-zA-Z0-9]+)/playlist/([a-zA-Z0-9]+)#},"spotify:user:\\1:playlist:\\2");
        cmd=%Q[spotify --uri="#{url}"]
        pid=spawn("#{cmd}", [:err, :out]=>"/dev/null",:pgroup=>true)
        Process.detach(pid)
      end
    end
    help :view_spotify_playlist, "view a spotify playlist", ":view_spotify_playlist [code]"
    aliasing :view_spotify_playlist, :vsp

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
    aliasing :dump_log, :dmp

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
    aliasing :clear_cache, :cc

    #command :mailbox do |target|
    #  if target
    #    targets = target.split(" ").map(&:to_i)
    #    raise Exception.new("need two parameters") if targets.size != 2
    #    threadnum, messagenum = targets
    #    mail = mailbox_cache[threadnum]
    #    instant_output(Item.new(info: :mail, content: {mail: mail, messagenum: messagenum}))
    #  else
    #    async {
    #      mails = facebook_mailbox
    #      mails.each {|m| mailbox_cache << m} if mails && !mails.empty?
    #      instant_output(Item.new(info: :mails))
    #    }
    #  end
    #end
    #help :mailbox, "read mailbox", ":mailbox [mail number]"
    #aliasing :mailbox, :m

    completion_proc = proc {|s|
      commands
        .map{|c|c[:pattern]}
        .map{|c|":#{c.to_s}"}
        .grep(/^#{Regexp.escape(s)}/)
    }
    Readline.completion_proc = completion_proc
  end
end
