%w(
  httparty
  koala
  readline
  yaml
  launchy
  eventmachine
  active_support/core_ext
  active_support/dependencies
).each { |lib| require lib }

%w(
 core
 get_token
 output
 command
 facebook
).each { |file| require_dependency File.expand_path("#{file}", ".") }

Facy.start({})
