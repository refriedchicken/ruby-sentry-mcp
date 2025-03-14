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
        attribute :project, Types::String.optional
        attribute :permalink, Types::String.optional
      end

      class IssueList < Dry::Struct
        transform_keys(&:to_sym)

        attribute :issues, Types::Array.of(Issue)
        attribute :total_count, Types::CoercibleInteger
      end

      class Server
        SENTRY_API_BASE = "https://sentry.io/api/0"

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
            stacktrace: extract_stacktrace(response),
            project: response.dig("project", "slug"),
            permalink: response["permalink"]
          )
        rescue => e
          raise "Failed to process issue: #{e.message}"
        end

        def list_issues(
          query: nil,
          status: "unresolved",
          limit: 10,
          stats_period: nil,  # e.g., "1h", "24h", "7d", "30d"
          start_date: nil,    # DateTime or ISO8601 string
          end_date: nil,      # DateTime or ISO8601 string
          first_seen: nil,    # DateTime or ISO8601 string
          last_seen: nil      # DateTime or ISO8601 string
        )
          params = {
            query: query,
            status: status,
            limit: limit,
            statsPeriod: stats_period,
            start: format_datetime(start_date),
            end: format_datetime(end_date),
            firstSeen: format_datetime(first_seen),
            lastSeen: format_datetime(last_seen)
          }.compact

          response = make_request(:get, "/organizations/strongmind-4j/issues/", params: params)
          
          issues = response.map do |issue|
            Issue.new(
              id: issue["id"],
              title: issue["title"],
              status: issue["status"],
              level: issue["level"],
              first_seen: issue["firstSeen"],
              last_seen: issue["lastSeen"],
              count: issue["count"],
              stacktrace: nil, # Stacktrace not included in list view
              project: issue.dig("project", "slug"),
              permalink: issue["permalink"]
            )
          end

          IssueList.new(
            issues: issues,
            total_count: issues.length
          )
        rescue ArgumentError => e
          raise # Re-raise ArgumentError directly
        rescue StandardError => e
          raise "Failed to list issues: #{e.message}"
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

        def make_request(method, path, params: {})
          # Ensure path starts with a forward slash
          path = "/#{path}" unless path.start_with?("/")
          url = URI.join(SENTRY_API_BASE + "/", path.sub(/^\//, ''))
          
          response = HTTP
            .headers(
              "Authorization" => "Bearer #{@auth_token}",
              "Content-Type" => "application/json"
            )
            .send(method, url, params: params)

          unless response.status.success?
            error_body = JSON.parse(response.body.to_s) rescue { "detail" => response.body.to_s }
            raise "API request failed (#{response.code}): #{error_body['detail']}"
          end

          JSON.parse(response.body.to_s)
        end

        def fetch_issue(issue_id)
          make_request(:get, "/issues/#{issue_id}/")
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

        def format_datetime(value)
          return nil if value.nil?
          
          case value
          when String
            # Assume it's already in ISO8601 format
            value
          when Time, DateTime
            value.iso8601
          else
            raise ArgumentError, "Invalid datetime format. Expected String, Time, or DateTime"
          end
        end
      end
    end
  end
end 