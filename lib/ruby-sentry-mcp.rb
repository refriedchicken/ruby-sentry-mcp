# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Ruby
  module Sentry
    module Mcp
      class Error < StandardError; end
    end
  end
end

loader.eager_load 