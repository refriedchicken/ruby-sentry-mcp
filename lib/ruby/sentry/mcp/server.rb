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
          # Add more context to the error
          raise "Failed to process issue: #{e.message}\nResponse: #{response.inspect}"
        end

        def list_issues(query: nil, status: "unresolved", limit: 10)
          params = {
            query: query,
            status: status,
            limit: limit
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

          # Calculate total count from the response data
          total_count = response.length

          IssueList.new(
            issues: issues,
            total_count: total_count
          )
        rescue => e
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
          url = "#{SENTRY_API_BASE}#{path}"
          
          response = HTTP
            .headers(
              "Authorization" => "Bearer #{@auth_token}",
              "Accept" => "application/json"
            )
            .send(method, url, params: params)
          
          unless response.status.success?
            raise "API request failed: #{response.body}"
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
      end
    end
  end
end 