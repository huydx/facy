module Facy
  module Help
    def helps
      @helps ||= []
    end

    def help(target, usage, example=nil)
      helps << {target: target, usage: usage, example: example} 
    end
  end

  extend Help
  init do
    command :help do |target|
      target = target.tap{|t|t.strip!}.gsub(':','').to_sym
      @helps.each do |h|
        if h[:target] == target
          instant_output(Item.new(
            info: :help,
            content: h[:usage],
            extra: h[:example]
          ))
        end
      end
    end
    help :help, "display usage for a command", ":help [command]"
  end
end
