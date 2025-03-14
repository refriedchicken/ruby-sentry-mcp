# frozen_string_literal: true

require "spec_helper"

RSpec.describe Ruby::Sentry::Mcp do
  it "has a version number" do
    expect(Ruby::Sentry::Mcp::VERSION).not_to be nil
  end

  it "initializes with required components" do
    expect(Ruby::Sentry::Mcp::Server).to be_a(Class)
    expect(Ruby::Sentry::Mcp::Issue).to be_a(Class)
  end
end
