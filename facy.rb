%w(
  httparty
  koala
  readline
  yaml
  thread
  launchy
  eventmachine
  active_support/core_ext
  active_support/dependencies
).each { |lib| require lib }

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
).each { |file| require_dependency File.expand_path("#{file}", ".") }

Facy.start({})
