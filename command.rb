module Facy
  module Command
    def commands
      @commands ||= []
    end

    def command(pattern, options={}, &block)
      commands << {pattern: pattern, block: block}
    end

    def execute(text)
      rule, target = match_single_command(text) || match_target_command(text)
      commands.each do |c|
        if rule.to_s == c[:pattern].to_s.split(":").first
          c[:block].call(target)
          return
        end
      end
    rescue Exception => e
      error e.backtrace
    end

    def match_single_command(text)
      text =~ /^:(\S*) (.+)$/
      return [$1, $2] if $1 && $2
      return nil
    end

    def match_target_command(text)
      text =~ /^:(\S*)$/
      return $1
    end
  end

  extend Command

  init do
    commands.clear
    command :post do |text|
      async { facebook_post(text) }
    end

    command :like do |post_code|
      item = post_code_reverse_map[post_code]
      post_id = item.id if item.is_a?(Item)
      async { facebook_like(post_id) }
    end

    command :exit do 
      stop_process  
    end

    command :open do |post_code|
      item = post_code_reverse_map[post_code]
      link = item.data.link if item.is_a?(Item)
      if link
        browse(link)
      else
        instant_output(Item.new(info: :error, content: "sorry this post can not be openned"))
      end
    end
  end
end
