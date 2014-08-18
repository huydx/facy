module Facy
  module OptParser
    def parse(argv)
      OptionParser.new do |opt|
        opt.version = VERSION 
        # -h, --h, --help is show usage.
        # -v, --v, --version is show version.
       
        # short option with require argument
        opt.on('--debug_log VALUE') do |v|
          config[:debug_log] = v
        end

        opt.parse!(argv)
      end
    end
  end

  extend OptParser
end
