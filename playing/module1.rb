module Foo
  module Bar1
    def init(&block)
      block.call
    end
  end
  extend Bar1
end
