module Facy
  module Facebook
    attr_reader :authen_hash, :rest
  
    def stream_printed
      @stream_printed ||= Set.new
    end

    def stream_print_queue
      @stream_print_queue ||= []
    end

    def user_id_cache_store
      @user_id_cache_store ||= ActiveSupport::Cache::MemoryStore.new
    end

    def user_id_cached?(id)
      !!user_id_cache_store.read(id)
    end
    
    #RULE: all facebook method should be prefix with facebook
    def facebook_stream_fetch
      streams  = @rest.rest_call("stream.get", @authen_hash).fetch("posts")
      #post_id, actor_id, message
      streams.each { |post| stream_print_queue << post }

      actor_ids = streams.map { |m| m["actor_id"] }
      not_cache_ids = actor_ids.select { |id| !user_id_cached?(id) }
      ids_names = GraphApi.facebook_ids2names(not_cache_ids)
      cache_user_ids(ids_names)
    rescue KeyError
    end

    def cache_user_ids(ids_names)
      ids_names.each { |hash| user_id_cache_store.write(hash[:id], hash[:name]) }
    end
    
    class GraphApi
      include HTTParty
      base_uri "http://graph.facebook.com"

      def self.facebook_id2name(id)
        return JSON.parse(get("/#{id}"))
      end

      def self.facebook_ids2names(ids_array)
        ids_array.map { |id| {name: facebook_id2name(id)["username"], id: id} }
      end
    end
  end 

  init do
    @rest = Koala::Facebook::RestAPI.new(config[:app_token])
    @authen_hash = {
      session_key: config[:session_key],
      uid: config[:uid]
    }
  end
  extend Facebook
end
