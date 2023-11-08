# frozen_string_literal: true

require "dry/configurable"
require "active_support/notifications"

require_relative "event"
require_relative "namespace"
require_relative "subscriber_adapter"
require_relative "evented_helper"

module Webhooks
  # This module is basically a fancy wrapper around `ActiveSupport::Notifications`.
  #
  # @example
  #   module MyPublisher
  #     include Webhooks::Publisher
  #
  #     config.namespace = :my_events
  #   end
  module Publisher
    extend(Dry::Configurable)

    setting(:backend, default: ActiveSupport::Notifications)
    setting(:adapter, default: Webhooks::SubscriberAdapter)
    setting(:namespace) { |v| Webhooks::Namespace.new(v, ".") if v.is_a?(Symbol) || v.is_a?(String) }

    def self.included(other)
      super
      other.extend(ClassMethods)
      # Have to extend `Dry::Configurable` since including this module wont copy over the methods.
      other.extend(Dry::Configurable)
      # Copy the settings defined above to `other`.
      other.instance_variable_set(:@_settings, _settings.dup)
    end

    # Class methods for a `Webhooks::Publisher`.
    module ClassMethods
      # Used to namespace subscribers and events.
      #
      # @return [Webhooks::Namespace]
      def namespace
        config.namespace
      end

      # The notification backend to use.
      #
      # @return [ActiveSupport::Notifications]
      def backend
        config.backend
      end

      # An adapter class to wrap the subscriber.
      #
      # @return [Class<Webhooks::SubscriberAdapter>]
      def adapter
        config.adapter
      end

      # Subscribe to specific event.
      #
      # You can subscribe to one specific event by using the events entire name like 'payout.created' or subscribe
      # to all payout events by using just 'payout'.
      #
      # @param [String,Symbol,nil] event_id
      # @param [Proc,#call,nil] callable
      # @param [Proc,nil] block
      # @return [void]
      def subscribe(event_id, callable=nil, &block)
        raise ArgumentError, "Both callable and block cannot be nil" if callable.nil? && block.nil?

        callable ||= block
        # Remove any duplicate subscribers.
        # Doing this prevents duplicating subscribers when reloading in dev.
        # We remove the old subscriber since it is possibly stale.
        subscribers[event_id].each do |s|
          backend.unsubscribe(s.subscriber) if s.callable == callable
        end

        backend.subscribe(namespace.to_regexp(event_id), adapter.call(callable, event_id))
      end

      # Get a hash of events and the subscribers.
      #
      # @return [Hash{String => Array<Webhooks::EventedHelper>}]
      def subscribers
        # Creating a hash that defaults to an array so we don't have to check for `nil` when using it.
        Hash.new { |h, k| h[k] = [] }.tap do |h|
          # Using the regex source in the namespace and the pattern to make sure to only get subscribers who belong
          # to the current namespace.
          name = namespace.to_regexp.source
          # The `ActiveSupport::Notifications::Fanout` class doesn't expose the subscribers and changing
          # `ActiveSupport::Notifications.notifier` will change it for the entire application.
          # If the pattern isn't a string then it's added to `@other_subscribers` and we always use a regex
          # for the pattern.
          backend.notifier.instance_variable_get(:@other_subscribers).each do |s|
            # If the subscribers pattern includes the same pattern as this namespace then include it.
            if (sub = Webhooks::EventedHelper.new(s)).pattern.source.start_with?(name)
              h[sub.event_id] << sub
            end
          end
        end
      end

      # Removes all subscribers of the specific event.
      #
      # @param [String,Symbol,nil] event_id
      # @return [void]
      def unsubscribe(event_id)
        subscribers[event_id].each do |s|
          # Pass the actual subscriber object to unsubscribe so it's deleted from the array.
          # If you pass a string then it only adds that string to the exclusion list for whatever
          # pattern it matches against.
          backend.unsubscribe(s.subscriber)
        end
      end

      # Check if an event is being listened for.
      #
      # @param [String,Symbol,nil] event_id
      # @return [Boolean]
      def listening?(event_id)
        backend.notifier.listening?(namespace.call(event_id))
      end

      # Subscribe to all events.
      #
      # @param [Proc,#call,nil] callable
      # @param [Proc,nil] block
      # @return [void]
      def all(callable=nil, &block)
        subscribe(nil, callable, &block)
      end

      # Calls all subscribers for the event.
      #
      # @param [String,Symbol,nil] event_id
      # @param [Object,nil] payload
      # @return [void]
      def publish(event_id, payload)
        backend.publish(namespace.call(event_id), Webhooks::Event.new(payload))
      end
    end
  end
end
