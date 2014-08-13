module Facy
  module Command
    def commands
      @commands ||= []
    end

    def command(pattern, options={}, &block)
      commands << {pattern: pattern, block: block}
    end

    def execute(text)
      text =~ /^:(\S*) (.+)$/ 
      rule, target = $1, $2
      commands.each do |c|
        if rule.to_s == c[:pattern].to_s.split(":").first
          c[:block].call(target) 
        end
      end
    end
  end

  extend Command

  init do
    commands.clear
    command :post do |text|
      async { facebook_post(text) }
    end

    command :like do |post_id|
      async { facebook_like(post_id) }
    end
  end
end
