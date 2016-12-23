module Facy
  module Facebook
    attr_reader :authen_hash, :rest

    module ConnectionStatus
      NORMAL    = 0
      ERROR     = 1
      SUSPENDED = 2
    end

    def facebook_me
      @graph.api("/me?fields=id,name")
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Koala::Facebook::APIError
      puts "failed facebook_me"
      expired_session
    rescue Exception => e
      error e
    end

    def facebook_status
      @status ||= ConnectionStatus::NORMAL
    end

    #RULE: all facebook method should be prefix with facebook
    def facebook_stream_fetch
      return unless facebook_status == ConnectionStatus::NORMAL
      #streams = @graph.get_connections("me", "feed") #home
      #streams.each { |post| stream_print_queue << graph2item(post) }
      scwd=File.dirname(__FILE__)
      streams_options=""
      if config[:show_latest_newsfeed]
		streams_options+="--show-latest "
	  end
	  if config[:id_timestamp_last_news_feed] != 0
		streams_options+="--newer-than=#{config[:id_timestamp_last_news_feed]} " #reduce data transmission/server load
	  end
	  #--web-security=no is for ajax facebook videos. it has to connect to cdn
      streams = `casperjs --ssl-protocol=tlsv1 --web-security=no --prefs-folder="#{config[:session_file_folder]}" --user-agent="#{config[:user_agent]}" --cookies-file="#{config[:fb_cookiejar]}" --num-result-pages=#{config[:news_feed_pages]} #{streams_options} #{scwd}/facebook-news-feed.js`
      if streams.length <= 0
        return
      end
      streams = JSON.parse(streams)
      streams.each do |post|
          if post["id"].to_i > config[:id_timestamp_last_news_feed]
            config[:id_timestamp_last_news_feed] = post["id"].to_i
          end
          #puts "post: "+post.inspect
          stream_print_queue << www2item(post)
      end
      log(:info, "fetch stream ok")
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Koala::Facebook::APIError => e
      puts "failed facebook_stream_fetch"
      error e.message
      expired_session
    rescue Exception => e
      error e
    end

    def facebook_notification_fetch
      return unless facebook_status == ConnectionStatus::NORMAL
      #notifications = @graph.get_connections("me", "notifications") #deprecated
      #notifications.each { |notifi| notification_print_queue << graph2item(notifi) }
      scwd=File.dirname(__FILE__)
      notification_options = %Q[--ssl-protocol=tlsv1 --user-agent="#{config[:user_agent]}" --cookies-file="#{config[:fb_cookiejar]}" --num-result-pages=#{config[:notification_pages]}]
      if config[:unread_notifications_only]
        notification_options += "--unread-only "
      end
      if config[:id_timestamp_last_notifications] != 0
        notification_options += "--newer-than=#{config[:id_timestamp_last_notifications]} " #reduce data transfer/server load
      end
      notifications = `casperjs #{notification_options} #{scwd}/facebook-notifications.js`
      if notifications.length <= 0
        return
      end
      notifications = JSON.parse(notifications)
      notifications.each do |notifi|
          if notifi["date"].to_i > config[:id_timestamp_last_notifications]
			config[:id_timestamp_last_notifications] = notifi["date"].to_i
          end
          notification_print_queue << www2item(notifi)
      end
      log(:info, "fetch notification ok")
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Koala::Facebook::APIError => e
      puts "failed facebook_notification_fetch"
      error e.message
      #expired_session
    rescue Exception => e
      error e
    end

    def facebook_post(text)
      @graph.put_wall_post(text)
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Koala::Facebook::APIError
      puts "failed facebook_post"
      expired_session
    rescue Exception => e
      error e
    end


    def facebook_like(post_id)
      @graph.put_like(post_id)
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Koala::Facebook::APIError
      puts "failed facebook_like"
      expired_session
    rescue Exception => e
      error e
    end

    def facebook_set_seen(notification_id)
      @graph.put_connections("#{notification_id}", "unread=false")
    rescue Koala::Facebook::ServerError => e
      retry_wait
    rescue Koala::Facebook::APIError => e
      puts "failed facebook_set_seen"
      error e.message
      expired_session
    rescue Exception => e
      error e
    end

    def facebook_mailbox
      @graph.get_connections("me", "inbox") #deprecated
    rescue Koala::Facebook::ServerError => e
      retry_wait
    rescue Koala::Facebook::APIError => e
      puts "failed facebook_mailbox"
      error e.message
      #expired_session
    rescue Exception => e
      error e
    end


    def facebook_comment(post_id, comment)
      @graph.put_comment(post_id, comment)
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Koala::Facebook::APIError
      puts "failed facebook_comment"
      expired_session
    rescue Exception => e
      error e
    end

    def expired_session
      if File.exists?(session_file)
        FileUtils.rm(session_file)
      end
      instant_output(Item.new(info: :info, content: "Please restart facy to obtain new access token!"))
      stop_process
    end

    def retry_wait
      log(:error, "facebook server error, need retry")
      instant_output(Item.new(info: :error, content: "facebook server error, retry in #{config[:retry_interval]} seconds"))
      sleep(config[:retry_interval])
    end

    def login
      token = config[:access_token]
      @graph = Koala::Facebook::API.new(token)
      Koala.config.api_version = "v#{config[:facebook_api_version]}"
      log(:info, "login ok at facebook module: #{@graph}")
    end
  end

  extend Facebook

  init do
    login
  end
end
