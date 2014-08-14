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

    command :like do |post_id|
      async { facebook_like(post_id) }
    end

    command :exit do 
      stop_process  
    end
  end
end
