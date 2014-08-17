module Facy
  module Facebook
    module ConnectionStatus
      NORMAL  = 0
      ERROR   = 1
    end

    attr_reader :authen_hash, :rest

    #RULE: all facebook method should be prefix with facebook
    def facebook_stream_fetch
      streams = @graph.get_connections("me", "home")
      streams.each { |post| stream_print_queue << graph2item(post) }
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Exception => e
      error e
    end

    def facebook_notification_fetch
      notifications = @graph.get_connections("me", "notifications")
      notifications.each { |notifi| notification_print_queue << graph2item(notifi) }
    rescue Koala::Facebook::ServerError
      retry_wait
    rescue Exception => e
      error e
    end

    def facebook_post(text)
      @graph.put_wall_post(text)
    rescue Exception => e
      error e 
    end

    def facebook_like(post_id)
      @graph.put_like(post_id)
    rescue Exception => e
      error e 
    end

    def facebook_set_seen(notification_id)
      @graph.put_connection("#{notification_id}", "unread=false") 
    rescue Exception => e
      error e
    end

    def facebook_comment(post_id, comment)
      @graph.put_comment(post_id, comment)
    rescue Exception => e
      error e
    end

    def retry_login
      login
    end

    def retry_wait
      instant_output(Item.new(info: :error, content: "facebook connection error, retry in #{config[:retry_interval]} seconds"))
      sleep(config[:retry_interval])
    end

    def status
      @status ||= ConnectionStatus::NORMAL
    end

    def login
      token = config[:access_token]
      @graph = Koala::Facebook::API.new(token)
    end
  end 

  extend Facebook
  
  init do
    login    
  end
end
