module Facy
  module Facebook
    attr_reader :authen_hash, :rest
  
    def stream_printed
      @stream_printed ||= Set.new
    end

    def stream_print_queue
      @stream_print_queue ||= []
    end

    def notification_printed
      @notification_printed ||= Set.new
    end

    def notification_print_queue
      @notification_print_queue ||= []
    end

    #RULE: all facebook method should be prefix with facebook
    def facebook_stream_fetch
      streams = @graph.get_connections("me", "home")
      streams.each { |post| stream_print_queue << post }
    end

    def facebook_notification_fetch
      notifications = @graph.get_connections("me", "notifications")
      notifications.each { |notifi| notification_print_queue << notifi }
    end

    def facebook_post(text)
      raise FacebookGraphReqError unless @graph.put_wall_post(text).fetch("id")
    end

    def facebook_like(post_id)
      raise FacebookGraphReqError unless @graph.put_like(post_id)
    end
  end 

  init do
    oauth = Koala::Facebook::OAuth.new(
      config[:app_id], 
      config[:app_secret], 
      config[:redirect_uri]
    )
    token = oauth.get_token_from_session_key(config[:session_key])
    @graph = Koala::Facebook::API.new(token) 
  end
  extend Facebook

  class FacebookGraphReqError < Exception ; end
end
