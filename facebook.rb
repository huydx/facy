module Facy
  module Facebook
    attr_reader :authen_hash, :rest
  
    def stream_printed
      @stream_printed ||= Set.new
    end

    def stream_print_queue
      @stream_print_queue ||= []
    end

    #RULE: all facebook method should be prefix with facebook
    def facebook_stream_fetch
      streams = @graph.get_connections("me", "home")
      streams.each { |post| stream_print_queue << post }
    rescue KeyError
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
end
