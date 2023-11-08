# frozen_string_literal: true

RSpec.describe Webhooks do
  it "has a version number" do
    expect(Webhooks::VERSION).not_to be_nil
  end
end
