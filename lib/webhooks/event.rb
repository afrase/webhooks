# frozen_string_literal: true

module Webhooks
  # A class to wrap the provided webhook payload.
  class Event
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end
  end
end
