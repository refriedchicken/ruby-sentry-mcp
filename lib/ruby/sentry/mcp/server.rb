# frozen_string_literal: true

require "sentry-ruby"
require "dry-struct"
require "dry-types"
require "json"
require "http"
require "uri"

module Ruby
  module Sentry
    module Mcp
      module Types
        include Dry.Types()
        
        # Custom types with coercion
        CoercibleInteger = Types::Coercible::Integer
        CoercibleDateTime = Types::JSON::DateTime.constructor(proc { |value|
          case value
          when String then Time.parse(value)
          else value
          end
        })
      end

      class Issue < Dry::Struct
        transform_keys(&:to_sym)

        # Use coercible types that will automatically convert strings
        attribute :id, Types::String
        attribute :title, Types::String
        attribute :status, Types::String
        attribute :level, Types::String
        attribute :first_seen, Types::CoercibleDateTime
        attribute :last_seen, Types::CoercibleDateTime
        attribute :count, Types::CoercibleInteger
        attribute :stacktrace, Types::String.optional
      end

      class Server
        def initialize(auth_token:)
          @auth_token = auth_token
          configure_sentry
        end

        def get_sentry_issue(issue_id_or_url)
          issue_id = extract_issue_id(issue_id_or_url)
          response = fetch_issue(issue_id)
          
          Issue.new(
            id: response["id"],
            title: response["title"],
            status: response["status"],
            level: response["level"],
            first_seen: response["firstSeen"],
            last_seen: response["lastSeen"],
            count: response["count"],
            stacktrace: extract_stacktrace(response)
          )
        rescue => e
          # Add more context to the error
          raise "Failed to process issue: #{e.message}\nResponse: #{response.inspect}"
        end

        private

        def configure_sentry
          ::Sentry.init do |config|
            config.dsn = @auth_token
          end
        end

        def extract_issue_id(issue_id_or_url)
          return issue_id_or_url unless issue_id_or_url.include?("/")

          uri = URI.parse(issue_id_or_url)
          path_components = uri.path.split("/")
          path_components.select { |c| !c.empty? }.last
        end

        def fetch_issue(issue_id)
          # Make the actual Sentry API call
          response = HTTP.headers(
            "Authorization" => "Bearer #{@auth_token}",
            "Accept" => "application/json"
          ).get("https://sentry.io/api/0/issues/#{issue_id}/")
          
          unless response.status.success?
            raise "Failed to fetch issue: #{response.body}"
          end
          
          JSON.parse(response.body.to_s)
        end

        def extract_stacktrace(response)
          # Extract stacktrace from the latest event
          frames = response.dig("latestEvent", "entries", 0, "data", "values", 0, "stacktrace", "frames")
          return nil unless frames

          frames.map { |frame| format_frame(frame) }.join("\n")
        end

        def format_frame(frame)
          [
            frame["filename"],
            frame["function"],
            frame["lineNo"]
          ].compact.join(":")
        end
      end
    end
  end
end 