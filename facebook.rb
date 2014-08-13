module Facy
  module Facebook
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
      ret = @graph.put_wall_post(text)
      instant_output(Item.new(info: 'success', message: "post #{ret["id"]} has been posted to your wall")) if ret["id"]
    rescue Exception => e
      error e 
    end

    def facebook_like(post_id)
      ret = @graph.put_like(post_id)
      instant_output(Item.new(info: :info, content: "like success")) if ret
    rescue Exception => e
      error e 
    end

    def retry_login
      login
    end

    def retry_wait
      sleep(config[:retry_interval])
    end

    def login
      @oauth = Koala::Facebook::OAuth.new(
        config[:app_id], 
        config[:app_secret], 
        config[:redirect_uri]
      )
      token = @oauth.get_token_from_session_key(config[:session_key])
      @graph = Koala::Facebook::API.new(token)
    end
  end 

  extend Facebook
  
  init do
    login    
  end
end
