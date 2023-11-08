# frozen_string_literal: true

module Webhooks
  # This class holds the reference to a receiver and the method to call on that receiver.
  # The `Webhooks::Subscriber` uses this because a method may not have been defined yet when `subscribe_to` is called.
  class LazyCaller
    attr_reader :receiver, :method_name

    def initialize(receiver, method_name)
      @receiver = receiver
      @method_name = method_name
    end

    def call(*args)
      receiver.public_send(method_name, *args)
    end

    # Compare using the receiver and method.
    # When rails does a reload the receiver will be different even when the class/module is still the same since the
    # constants is redefined.
    def ==(other)
      other.is_a?(LazyCaller) && real_method_name == other.real_method_name && receiver_name == other.receiver_name
    end
    alias eql? ==

    # Try to normalize the method name. When referencing a method on a receiver this will be the actual method name but
    # if the receiver is a `Method` then the method name will be `call`. The method class keeps a reference to the
    # actual methods name. This way if something is subscribed to in two places using a symbol of the method name
    # and using `method()` they will be equal.
    #
    # When a proc is used we just compare if it's in the same file and starts on the same line. That's the best we can
    # do to compare them. This shouldn't be a problem though since it only really effects development.
    #
    # @return [String]
    def real_method_name
      case receiver
      when Proc
        receiver.source_location.to_s
      when Method
        receiver.name.to_s
      else
        method_name.to_s
      end
    end

    # Try to normalize the name of the receiver. Usually a module or class name.
    #
    # @return [String]
    def receiver_name
      case receiver
      when Proc
        # The `real_method_name` will handle the actual compare for a proc.
        "Proc"
      when Method
        receiver.receiver.to_s
      else
        receiver.to_s
      end
    end
  end
end
