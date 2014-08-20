# coding: utf-8

module Facy
  module Converter
    #convert facebook graph return to Item#class
    def graph2item(graph_item)
      id = graph_item["id"]
      if id =~ /^notif_(.+)$/
        item = Item.new({
          id: id,
          info: :notification,
          data: {
            user: graph_item["from"]["name"],
            content: graph_item["title"],
          },
          date: graph_item["created_time"],
          link: graph_item["link"]
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
            "share a photo: #{graph_item['message'] || graph_item['link']}"
          when "checkin"
            "checkin"
          when "video"
            "share a video: #{graph_item['message']}"
          when "link"
            "#{graph_item["message"]} #{graph_item["link"]} #{graph_item["name"]}"
          end
        
        link = 
          (graph_item["actions"] && graph_item["actions"].first["link"]) ||
          graph_item["link"]
        
        likes = graph_item["likes"] && graph_item["likes"]["data"] || []
        comments = graph_item["comments"] && graph_item["comments"]["data"] || []

        like_count = likes.size
        comment_count = comments.size

        item = Item.new({
          id: graph_item["id"],
          info: :feed,
          data: {
            type: graph_item["type"],
            user: graph_item["from"]["name"],
            content: content,
            picture: graph_item["picture"],
            link: link,
            like_count: like_count,
            likes: likes, 
            comment_count: comment_count,
            comments: comments,
            date: DateTime.parse(graph_item["created_time"]),
          },
          date: graph_item["created_time"],
        })
      end
      item.raw = graph_item
      return item
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
