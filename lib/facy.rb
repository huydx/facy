%w(
  koala
  readline
  yaml
  thread
  launchy
  eventmachine
  active_support
  active_support/core_ext
  active_support/dependencies
).each { |lib| require lib }

begin 
  require "rmagick"
rescue LoadError
  begin
    require "RMagick"
  rescue LoadError
    p "can not require rmagick library in this computer"
    exit
  end
end

Thread.abort_on_exception = true
Encoding.default_external = Encoding.find('UTF-8')

%w(
 core_ext
 core
 logger
 get_token
 output
 command
 help
 facebook
 input_queue
 command
 converter
 exception
 option_parser
 image_viewer
).each { |file| require_dependency File.expand_path("../facy/#{file}", __FILE__) }
