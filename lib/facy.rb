%w(
  koala
  readline
  yaml
  thread
  launchy
  eventmachine
  active_support/core_ext
  active_support/dependencies
).each { |lib| require lib }

Thread.abort_on_exception = true
Encoding.default_external = Encoding.find('UTF-8')

%w(
 core_ext
 core
 get_token
 output
 command
 facebook
 input_queue
 command
 converter
 exception
).each { |file| require_dependency File.expand_path("../facy/#{file}", __FILE__) }
