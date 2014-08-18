module Facy
  module Logger
    def log_file
      File.expand_path(config[:log_file_name], config[:log_folder])
    end
    
    def log_queue
      @log_queue ||= []
    end

    def log(info, message)
      return unless config[:debug_log]
      log_queue << {info: info.to_s, message: message}
    end
    
    def dump_log
      File.open(log_file, "w") do |f|
        log_queue.each {|m| f.write "#{m[:info]}    #{m[:message]} \n"}
      end 
    rescue Exception => e
      error e
    end
  end

  extend Logger
end
