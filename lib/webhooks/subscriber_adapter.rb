# frozen_string_literal: true

module Webhooks
  # ActiveSupports instrumentation calls subscribers with multiple arguments but we only care about the payload.
  # This wraps the callable and calls it with just the payload.
  # This also keeps a reference to the original event_id the subscriber is listening for since its value is lost
  # by the notification backend.
  class SubscriberAdapter
    # The adapter class needs to be callable. Could alias `new` to `call` but this is more readable.
    def self.call(callable, event_id=nil)
      new(callable, event_id)
    end

    attr_reader :event_id, :callable

    def initialize(callable, event_id)
      @callable = callable
      @event_id = event_id
    end

    def call(*args)
      # The last element is the payload.
      @callable.call(args.last)
    end
  end
end
