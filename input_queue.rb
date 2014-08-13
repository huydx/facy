module Facy
  module InputQueue
    def stream_printed
      @stream_printed ||= Set.new
    end

    def stream_print_queue
      @stream_print_queue ||= []
    end

    def notification_printed
      @notification_printed ||= Set.new
    end

    def notification_print_queue
      @notification_print_queue ||= []
    end

    def item_print_queue
      @item_print_queue ||= []
    end

    def insert_lock
      @insert_lock ||= Monitor.new
    end
    
    def insert_item(item)
      insert_lock.synchronize do
        _insert_item(item)
      end
    end

    def _insert_item(item)
      item_print_queue << item
    end
  end

  extend InputQueue
end
