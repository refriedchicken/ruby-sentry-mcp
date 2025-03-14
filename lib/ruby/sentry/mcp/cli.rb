# frozen_string_literal: true

require "dry/cli"
require "json"
require "socket"
require_relative "server"

module Ruby
  module Sentry
    module Mcp
      module CLI
        module Commands
          extend Dry::CLI::Registry

          class Start < Dry::CLI::Command
            desc "Start the Sentry MCP server"

            option :auth_token, type: :string, desc: "Sentry authentication token"
            option :port, type: :integer, default: 3000, desc: "Port to run the server on"

            def call(auth_token:, port: 3000, **)
              sentry_server = Server.new(auth_token: auth_token)
              
              puts "Starting Sentry MCP server on port #{port}..."
              tcp_server = TCPServer.new(port)
              
              loop do
                client = tcp_server.accept
                
                begin
                  # Read the HTTP request
                  request_line = client.gets
                  headers = {}
                  content_length = 0
                  
                  # Parse headers
                  while (line = client.gets.strip) && !line.empty?
                    key, value = line.split(": ", 2)
                    headers[key.downcase] = value
                    content_length = value.to_i if key.downcase == "content-length"
                  end
                  
                  # Read body if present
                  body = client.read(content_length) if content_length.positive?
                  
                  if body
                    request = JSON.parse(body)
                    response_data = case request["method"]
                                  when "get_sentry_issue"
                                    issue = sentry_server.get_sentry_issue(request["params"]["issue_id_or_url"])
                                    { result: issue.to_h }
                                  when "list_issues"
                                    params = request["params"] || {}
                                    result = sentry_server.list_issues(
                                      query: params["query"],
                                      status: params["status"],
                                      limit: params["limit"]
                                    )
                                    { result: result.to_h }
                                  else
                                    { error: "Unknown method" }
                                  end
                    
                    response_json = JSON.generate(response_data)
                    
                    # Send HTTP response
                    client.puts "HTTP/1.1 200 OK"
                    client.puts "Content-Type: application/json"
                    client.puts "Content-Length: #{response_json.bytesize}"
                    client.puts "Connection: close"
                    client.puts
                    client.puts response_json
                  else
                    # Handle non-POST or empty requests
                    client.puts "HTTP/1.1 400 Bad Request"
                    client.puts "Content-Type: application/json"
                    client.puts "Connection: close"
                    client.puts
                    client.puts JSON.generate(error: "Invalid request")
                  end
                rescue => e
                  # Send error response
                  error_json = JSON.generate(error: e.message)
                  client.puts "HTTP/1.1 500 Internal Server Error"
                  client.puts "Content-Type: application/json"
                  client.puts "Content-Length: #{error_json.bytesize}"
                  client.puts "Connection: close"
                  client.puts
                  client.puts error_json
                ensure
                  client.close
                end
              end
            end
          end

          register "start", Start
        end
      end
    end
  end
end 