# coding: utf-8

module Facy
  module Converter
    #convert facebook graph return to Item#class
    def graph2item(graph_item) #old
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

    #see http://unicode.org/Public/emoji/4.0/
    def pregenerate_emoji_pattern
      if @all_emoji_patterns.present?
        return
      end
      scwd=File.dirname(__FILE__)
      f = File.read("#{scwd}/emoji-data.txt")
      
      tp=[]
      ep=[]
      text_reps = ""
      emoji_reps = ""
      modsbase_reps = ""
      mods_reps = ""
      f.each_line { |line|
        if line[0] == "#"
          next
        elsif line.strip.empty?
          next
        elsif line.include? "; Emoji "
          a = line.split(';')
          str = a[0].strip
          if str.include? ".."
            a = str.split('..')
            x=("0x"+a[0]).to_i(16)
            y=("0x"+a[1]).to_i(16)
            a=(x..y).to_a.map { |c| %q[\\u]+"{%04x}" % c }
            tp += a
          else
            tp << "\\u{%s}" % str
          end
          str = "\\u{" + str + "}"
          str = str.gsub("..","}-\\u{")
          text_reps+=str
        elsif line.include? "; Emoji_Presentation "
          a = line.split(';')
          str = a[0].strip
          if str.include? ".."
            a = str.split('..')
            x=("0x"+a[0]).to_i(16)
            y=("0x"+a[1]).to_i(16)
            a=(x..y).to_a.map { |c| %q[\\u]+"{%04x}" % c }
            ep += a
          else
            ep << "\\u{%s}" % str
          end
          str = "\\u{" + str + "}"
          str = str.gsub("..","}-\\u{")
          emoji_reps+=str
        elsif line.include? "; Emoji_Modifier_Base "
          a = line.split(';')
          str = a[0].strip
          str = "\\u{" + str + "}"
          str = str.gsub("..","}-\\u{")
          modsbase_reps+=str
        elsif line.include? "; Emoji_Modifier "
          a = line.split(';')
          str = a[0].strip
          str = "\\u{" + str + "}"
          str = str.gsub("..","}-\\u{")
          mods_reps+=str
        end
      }

      sv=Set.new(tp) & Set.new(ep)
      sv=sv.to_a.join("").strip

      f = File.read("#{scwd}/emoji-zwj-sequences.txt")
      zwj_reps = ""
      f.each_line { |line|
        if line[0] == "#"
          next
        elsif line.strip.empty?
          next
        elsif line.include? "; Emoji_ZWJ_Sequence "
          a = line.split(';')
          str = a[0].strip
          str = "\\u{" + str + "}"
          str = str.gsub("..","}-\\u{")
          str = str.gsub(" ","}\\u{")
          zwj_reps+=str+"|"
        end
      }
      zwj_reps = zwj_reps[0...-1]
      
      presentation_text = %q[\uFE0E] #not used
      presentation_emoji = %q[\uFE0F]
      
      @@all_emoji_patterns = "#{zwj_reps}|[#{modsbase_reps}][#{mods_reps}]?|[#{emoji_reps}]|[#{sv}][#{presentation_emoji}#{presentation_text}]?"
    end

    def emoji_reserve_space(str,spaces=" ")
        #we put a space between the color emojis so they do not overlap
		return str.gsub(/(#{@@all_emoji_patterns})/, "\\1#{spaces}")
		#return 
    end

    #scraped version
    def www2item(graph_item)
      pregenerate_emoji_pattern

      id = graph_item["id"]
      if graph_item["info"] =~ /^:notification$/
        content = emoji_reserve_space(graph_item["data"]["content"]);
        item = Item.new({
          id: id,
          info: :notification,
          data: {
            user: graph_item["data"]["user"],
            content: content,
            emoji: graph_item["data"]["emoji"],
          },
          date: graph_item["date"],
          link: graph_item["data"]["link"]
        })
      else
        content = 
          case graph_item["data"]["type"]
          when "status"
            ": #{graph_item['data']['content']}"
          when "photo"
            "shared a photo: #{graph_item['data']['content'] || graph_item['data']['link']}"
          when "profile_pic"
            "updated their profile pic: #{graph_item['data']['content']}"
          when "cover_photo"
            "updated their cover photo."
          when "checkin"
            "checked in at \"#{graph_item['data']['user_location']}\": #{graph_item['data']['content']}"
          when "video"
            "shared a video: #{graph_item['data']['content']}"
          when "link"
            "shared a link: from: #{graph_item['data']['user']} | #{graph_item['data']['content']} #{graph_item['data']['link']} "
          when "liked"
            "liked a post: #{graph_item['data']['content']}"
          when "likes"
            "likes: #{graph_item['data']['user_next']}"
          when "commented"
            "commented: #{graph_item['data']['comment']} | for post: #{graph_item['data']['content']}"
          when "commented_with_video"
            emoji = ""
            if (config[:utilize_emojis])
              emoji = "🎥"
            else
              emoji = "video"
            end
            "commented with #{emoji}: #{graph_item['data']['comment']} | for post: #{graph_item['data']['content']}"
          when "commented_with_image"
            emoji = ""
            if (config[:utilize_emojis])
              emoji = "🖼"
            else
              emoji = "image"
            end
            "commented with #{emoji}: #{graph_item['data']['comment']} | for post: #{graph_item['data']['content']}"
          when "reacted"
            if config[:utilize_emojis]
              reaction = item.data.reaction
              reaction = reaction.sub(/Haha/, "😃 ")
              reaction = reaction.sub(/Sad/, "😢 ")
              reaction = reaction.sub(/Angry/, "😡 ")
              reaction = reaction.sub(/Wow/, "😮 ")
              reaction = reaction.sub(/Love/, "❤ ")            
            else
              reaction = item.data.reaction
              reaction = reaction.sub(/Haha/, ":Haha:")
              reaction = reaction.sub(/Sad/, ":Sad:")
              reaction = reaction.sub(/Angry/, ":Angry:")
              reaction = reaction.sub(/Wow/, ":Wow:")
              reaction = reaction.sub(/Love/, ":Love:")            
            end
            "reacted with #{reaction}: #{graph_item['data']['content']}"
          when "memory"
            "shared memory: #{graph_item['data']['content']}"
          when "tagged"
            "was tagged: #{graph_item['data']['content']}"
          when "watching_movie: #{graph_item['data']['content']}"
            "watching movie: #{graph_item['data']['content']}"
          when "traveling"
            "traveling to: #{graph_item['data']['user_location']}"
          when "commercial_ad"
            "(commerical ad): #{graph_item['data']['content']}"
          when "commercial_ad_video"
            "(commerical video ad): #{graph_item['data']['content']}"
          when "commercial_ad_endorsed"
            "likes \"#{graph_item['data']['next_user']}\": commerical ad: #{graph_item['data']['content']}"
          when "payment"
            "bought something at: #{graph_item['data']['user_next']}"
          when "group_post"
            "posts in \"#{graph_item['data']['user_next']}\" group: #{graph_item['data']['content']}"
          when "interested_in_event"
            "interested in event: name: #{graph_item['data']['event_name']} when: #{graph_item['data']['event_date']} | #{graph_item['data']['content']}"
          when "shared_group_event"
            "shared group event to \"#{graph_item['data']['user_next']}\" group: name: #{graph_item['data']['event_name']} when: #{graph_item['data']['event_date']} | #{graph_item['data']['content']}"
          when "shared_event"
            "shared event from \"#{graph_item['data']['user_next']}\": name: #{graph_item['data']['event_name']} when: #{graph_item['data']['event_date']} | #{graph_item['data']['content']}"
          when "video_was_live"
            "was live: #{graph_item['data']['content']}"
          when "replied"
            "replies with: #{graph_item['data']['comment']} | to: #{graph_item['data']['content']}"
          when "now_friends"
            "now friends: #{graph_item['data']['user_next']}: #{graph_item['data']['content']}"
          when "eating"
            "eating #{graph_item['data']['food']} #{graph_item['data']['user_location']}: #{graph_item['data']['content']}"
          when "video_live_now"
            "doing live video now: #{graph_item['data']['content']}"
          when "video_was_live"
            "did live video: #{graph_item['data']['content']}"
          when "shared_live_video"
            "shared live video: #{graph_item['data']['content']}"
          when "shared_textual_post"
            "shared #{graph_item['data']['user_next']}'s post: #{graph_item['data']['content']}"
          when "dating"
            "went out with #{graph_item['data']['user_next']}: #{graph_item['data']['content']}"
          when "dating_at"
            "went out with #{graph_item['data']['user_next']} at #{graph_item['data']['user_location']}: #{graph_item['data']['content']}"
          when "app_post"
            "posted via #{graph_item['data']['app_name']} app: #{graph_item['data']['content']}"
          when "mentioned"
            "was mentioned: #{graph_item['data']['content']}"
          when "birthday"
            "is celebrating a birthday today."
          else
            "#{graph_item['data']['type']}: #{graph_item['data']['content']}"
          end
        content = emoji_reserve_space(content);

        link = graph_item["data"]["link"]
        
        likes = graph_item['data']['likes']
        comment = graph_item['data']['comment']

        like_count = graph_item["data"]["like_count"]
        comment_count = graph_item["data"]["comments_count"]

        item = Item.new({
          id: graph_item["id"],
          info: :feed,
          data: {
            type: graph_item["data"]["type"],
            user: graph_item["data"]["user"],
            content: content,
            comment: comment,
            comment_sticker: graph_item["data"]["comment_sticker"],
            picture: graph_item["data"]["picture"],
            video: graph_item["data"]["video"],
            link: link,
            link_post: graph_item["data"]["link_post"],
            like_count: like_count,
            likes: likes, 
            comment_count: comment_count,
            share_count: graph_item["data"]["share_count"],
            react_scores: graph_item["data"]["react_scores"],
            reaction: graph_item["data"]["reaction"],
            comment: comment,
            date: DateTime.parse(graph_item["date"]),
          },
          date: graph_item["date"],
        })
      end
      #puts item.inspect
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
