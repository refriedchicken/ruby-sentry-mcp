# frozen_string_literal: true

require "bundler/setup"
Bundler.setup

require "logger"
debug_log = Logger.new($stdout)
debug_log.level = Logger::DEBUG

debug_log.debug "Setting up load path..."
lib_path = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
debug_log.debug "Load path configured: #{lib_path}"

debug_log.debug "Loading ruby-sentry-mcp..."
require "ruby-sentry-mcp"
debug_log.debug "ruby-sentry-mcp loaded"

debug_log.debug "Loading test dependencies..."
require "webmock/rspec"
require "pry"
debug_log.debug "Test dependencies loaded"

# Ensure all requests are stubbed in tests
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.before(:suite) do
    debug_log.debug "Starting test suite"
  end

  config.after(:suite) do
    debug_log.debug "Test suite completed"
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Enable the expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up WebMock after each test
  config.after(:each) do
    WebMock.reset!
  end
end
