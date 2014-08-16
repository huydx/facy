module Facy
  module Converter
    #convert facebook graph return to Item#class
    def graph2item(graph_item)
      id = graph_item["id"]
      if id =~ /^notif_(.+)$/
        Item.new({
          id: id,
          info: :notification,
          data: {
            user: graph_item["from"]["name"],
            content: graph_item["title"],
          },
          date: graph_item["created_time"],
        })
      else
        content = 
          case graph_item["type"]
          when "status"
            if graph_item["message"].nil?
              graph_item["story"]
            else
              graph_item["message"]
            end
          when "photo"
            "share a photo: #{graph_item['message']}"
          when "checkin"
            "checkin"
          when "video"
            "share a video: #{graph_item['message']}"
          when "link"
            if graph_item["message"].nil?
              graph_item["link"]
            else
              graph_item["message"]
            end
          end
        
        link = 
          (graph_item["actions"] && graph_item["actions"].first["link"]) ||
          graph_item["link"]

        Item.new({
          id: graph_item["id"],
          info: :feed,
          data: {
            type: graph_item["type"],
            user: graph_item["from"]["name"],
            content: content,
            link: link 
          },
          date: graph_item["created_time"],
        })
      end
    end
  end

  extend Converter

  class DeepStruct < OpenStruct
    def initialize(hash=nil)
      @table = {}
      @hash_table = {}

      if hash
        hash.each do |k,v|
          @table[k.to_sym] = (v.is_a?(Hash) ? self.class.new(v) : v)
          @hash_table[k.to_sym] = v
          new_ostruct_member(k)
        end
      end 
    end

    def to_h
      @hash_table
    end
  end
  class Item < DeepStruct; end
end
