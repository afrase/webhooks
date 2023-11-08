# frozen_string_literal: true

require_relative "webhooks/version"
require_relative "webhooks/publisher"
require_relative "webhooks/subscriber"

module Webhooks
  class Error < StandardError; end
  class UnknownHandlerError < Error; end
end
