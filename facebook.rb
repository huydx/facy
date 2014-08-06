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
      @user_id_cache_store ||= {}
    end

    def user_id_cache_dump
      File.open(File.expand_path(
        config[:user_id_cache_dump_file],
        config[:user_id_cache_dump_folder]), "wb") do |file|

        file.write Marshal.dump(user_id_cache_store)
      end
    end

    def user_id_cache_load
      data = Marshal.load(File.binread(File.expand_path(
        config[:user_id_cache_dump_file],
        config[:user_id_cache_dump_folder]
      )))
      data.each { |key, val| user_id_cache_store[key] = val }
    rescue Errno::ENOENT
    rescue Exception => e
      p e
    end

    def user_id_cached?(id)
      user_id_cache_store.include? id
    end

    def cache_user_id(id, name)
      user_id_cache_store[id] = name
    end

    #RULE: all facebook method should be prefix with facebook
    def facebook_stream_fetch
      streams  = @rest.rest_call("stream.get", @authen_hash).fetch("posts")
      actor_ids = streams.map { |m| m["actor_id"] }
      not_cache_ids = actor_ids.select { |id| !user_id_cached?(id) }
      ids_names = facebook_ids2names(not_cache_ids)
      streams.each { |post| stream_print_queue << post }

      stop_animation = true
    rescue KeyError
    end

    def facebook_ids2names(ids_array)
      ids_array.map { |id| 
        json_ret = GraphApi.facebook_id2name(id)
        cache_user_id(json_ret["id"], json_ret["username"]) unless user_id_cached?(id)
        {name: json_ret["username"], id: json_ret["id"]} 
      }
    end
    
    class GraphApi
      include HTTParty
      base_uri "http://graph.facebook.com"

      def self.facebook_id2name(id)
        json_ret = JSON.parse(get("/#{id}"))
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
