# frozen_string_literal: true

require "zeitwerk"
require "dry-struct"
require "dry-types"
require "http"
require "json"
require "uri"
require "logger"

# Set up debug logging
debug_log = Logger.new($stdout)
debug_log.level = Logger::DEBUG

module Ruby
  module Sentry
    module Mcp
      class Error < StandardError; end
    end
  end
end

# Initialize custom loader
debug_log.debug "Initializing loader..."
loader = Zeitwerk::Loader.new
loader.logger = debug_log

# Configure loader
debug_log.debug "Configuring loader..."
lib_path = File.expand_path(__dir__)
loader.push_dir(lib_path)
loader.ignore("#{lib_path}/ruby-sentry-mcp.rb")

# Configure inflections
loader.inflector.inflect(
  "cli" => "CLI",
  "mcp" => "Mcp"
)

# Load files explicitly first
debug_log.debug "Loading core files..."
require_relative "ruby/sentry/mcp/version"
require_relative "ruby/sentry/mcp/server"
require_relative "ruby/sentry/mcp/cli"

# Setup loader after explicit requires
debug_log.debug "Setting up loader..."
loader.setup
debug_log.debug "Setup complete"

# No eager loading needed since we've required everything explicitly
debug_log.debug "Initialization complete" 