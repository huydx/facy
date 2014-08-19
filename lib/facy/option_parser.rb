module Facy
  module OptParser
    def parse(argv)
      OptionParser.new do |opt|
        # -h, --h, --help is show usage.
        # -v, --v, --version is show version.
       
        # short option with require argument
        opt.on('--debug_log VALUE') do |v|
          config[:debug_log] = v
        end

        opt.on('--enable_img_view VALUE') do |v|
          config[:enable_img_view] = v
        end

        opt.parse!(argv)
      end
    end
  end

  extend OptParser
end
