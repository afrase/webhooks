# frozen_string_literal: true

module Webhooks
  # This class is intended to wrap a `ActiveSupport::Notifications::Fanout::Subscribers::Evented` object to make it
  # easier to work with. When you subscribe to an event your pattern and callable get captured in that class but aren't
  # exposed publicly.
  # We want to get access to parts of the original subscriber so we can actually remove it from the list of subscribers
  # not just make the pattern exclude a specific event which is what happens when trying to unsubscribe using only the
  # event pattern.
  class EventedHelper
    # @return [ActiveSupport::Notifications::Fanout::Subscribers::Evented]
    attr_reader :subscriber

    def initialize(subscriber)
      @subscriber = subscriber
    end

    # Get the underlying callable object.
    #
    # @return [Object,nil]
    def delegate
      @delegate ||= subscriber.instance_variable_get(:@delegate)
    end

    # If this subscriber is from `Webhooks::SubscriberAdapter` it will have the reference to the original callable.
    #
    # @return [Proc,#call,nil]
    def callable
      delegate.callable if delegate.respond_to?(:callable)
    end

    # Again, if this subscriber is one of ours then it will have the event_id getter.
    #
    # @return [String,nil]
    def event_id
      delegate.event_id if delegate.respond_to?(:event_id)
    end

    # The pattern is wrapped in a class so that exclusions can be added. Just return the original Regexp pattern.
    #
    # @return [Regexp]
    def pattern
      @subscriber.pattern.pattern
    end

    # Make it easier to grok arrays of this object.
    def inspect
      "#<#{self.class.name}:#{format("%#016x", (object_id << 1))} event_id=#{event_id.inspect} callable=#{callable}>"
    end
  end
end
