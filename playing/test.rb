require "active_support/dependencies"

%w(
  module1
  module2
).each { |m| require_dependency "./#{m}"}
