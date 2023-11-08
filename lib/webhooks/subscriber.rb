# frozen_string_literal: true

require_relative "lazy_caller"

module Webhooks
  # Include this module in a class or module to be able to easily subscribe to events from a specific publisher.
  #
  # One reason for doing things this way is it makes it easy to write specs since you have access to the methods
  # that get called for events.
  #
  # @example
  #   module MySubscriber
  #     include Webhooks::Subscriber.publisher(MyPublisher)
  #
  #     subscribe_to 'my.event', with: :event_method
  #     def self.event_method(event); end
  #
  #     # If `with` is nil then `call` is used.
  #     subscribe_to 'my.event'
  #     def self.call(event); end
  #   end
  module Subscriber
    # @param [Class] pub_class
    # @return [Webhooks::Subscriber::SubscriberModule]
    def self.publisher(pub_class)
      SubscriberModule.new(pub_class)
    end

    # To be able to `include` this into a module or class we have to subclass `Module`.
    # The reason we need a class is to be able to hold the reference to the publisher class that's passed by the
    # receiver.
    class SubscriberModule < ::Module
      def initialize(publisher)
        super()
        @publisher = publisher
      end

      private

      def included(other)
        super
        # For the class methods to have access to the publisher, a method with the reference needs to be
        # created in the receiver. There might be a better way to do this but this works.
        other.instance_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def self.publisher # def self.publisher
            #{@publisher}    #   Publisher
          end                # end
        RUBY
        other.extend(ClassMethods)
      end

      # Class methods for a `Webhooks::Subscriber`
      module ClassMethods
        # Subscribe to a particular event.
        #
        # @param [String,Symbol] event_id
        # @param [Proc,Symbol,String,#call,nil] with
        def subscribe_to(event_id, with: nil, &block)
          callable = case with
                     when nil
                       LazyCaller.new(block || self, :call)
                     when ->(w) { w.respond_to?(:call) }
                       LazyCaller.new(with, :call)
                     when Symbol, String
                       LazyCaller.new(self, with)
                     else
                       raise Webhooks::UnknownHandlerError, "Unknown handler '#{with.inspect}'"
                     end

          event_id.to_s.casecmp("all").zero? ? publisher.all(callable) : publisher.subscribe(event_id, callable)
        end
      end
    end
  end
end
