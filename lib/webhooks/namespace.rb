# frozen_string_literal: true

module Webhooks
  # Used to namespace subscriber names.
  class Namespace
    attr_reader :namespace, :delimiter

    # @param [String,Symbol,nil] namespace
    # @param [String,Symbol,nil] delimiter
    def initialize(namespace, delimiter)
      @namespace = namespace.to_s
      @delimiter = delimiter.to_s
    end

    # @param [String,Symbol,nil] name
    # @return [String]
    def call(name=nil)
      "#{namespace}#{delimiter}#{name}"
    end

    # @param [String,Symbol,nil] name
    # @return [Regexp]
    def to_regexp(name=nil)
      /^#{Regexp.escape(call(name.to_s))}/
    end
  end
end
