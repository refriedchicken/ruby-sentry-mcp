require "spec_helper"
require "webmock/rspec"

RSpec.describe Ruby::Sentry::Mcp::Server do
  let(:auth_token) { "test_auth_token" }
  let(:server) { described_class.new(auth_token: auth_token) }
  let(:base_url) { "https://sentry.io/api/0" }

  before do
    WebMock.disable_net_connect!
  end

  describe "#get_sentry_issue" do
    let(:issue_id) { "12345" }
    let(:issue_url) { "https://sentry.io/organizations/test-org/issues/12345/" }
    let(:api_response) do
      {
        id: issue_id,
        title: "Test Error",
        status: "unresolved",
        level: "error",
        firstSeen: "2024-03-14T00:00:00Z",
        lastSeen: "2024-03-14T01:00:00Z",
        count: "42",
        project: { slug: "test-project" },
        permalink: "https://sentry.io/issues/12345",
        latestEvent: {
          entries: [{
            data: {
              values: [{
                stacktrace: {
                  frames: [{
                    filename: "test.rb",
                    function: "test_method",
                    lineNo: 42
                  }]
                }
              }]
            }
          }]
        }
      }
    end

    before do
      stub_request(:get, "#{base_url}/issues/#{issue_id}/")
        .with(headers: { "Authorization" => "Bearer #{auth_token}" })
        .to_return(status: 200, body: api_response.to_json)
    end

    context "when using issue ID" do
      it "fetches and formats the issue correctly" do
        issue = server.get_sentry_issue(issue_id)
        
        expect(issue.id).to eq(issue_id)
        expect(issue.title).to eq("Test Error")
        expect(issue.status).to eq("unresolved")
        expect(issue.level).to eq("error")
        expect(issue.count).to eq(42)
        expect(issue.project).to eq("test-project")
        expect(issue.permalink).to eq("https://sentry.io/issues/12345")
        expect(issue.stacktrace).to eq("test.rb:test_method:42")
      end
    end

    context "when using issue URL" do
      it "extracts the ID and fetches the issue" do
        issue = server.get_sentry_issue(issue_url)
        
        expect(issue.id).to eq(issue_id)
      end
    end

    context "when API request fails" do
      before do
        stub_request(:get, "#{base_url}/issues/#{issue_id}/")
          .to_return(status: 404, body: { detail: "Not found" }.to_json)
      end

      it "raises an error with context" do
        expect { server.get_sentry_issue(issue_id) }
          .to raise_error(/API request failed/)
      end
    end
  end

  describe "#list_issues" do
    let(:issues_response) do
      [
        {
          id: "1",
          title: "First Error",
          status: "unresolved",
          level: "error",
          firstSeen: "2024-03-14T00:00:00Z",
          lastSeen: "2024-03-14T01:00:00Z",
          count: "10",
          project: { slug: "test-project" },
          permalink: "https://sentry.io/issues/1"
        },
        {
          id: "2",
          title: "Second Error",
          status: "unresolved",
          level: "error",
          firstSeen: "2024-03-14T02:00:00Z",
          lastSeen: "2024-03-14T03:00:00Z",
          count: "5",
          project: { slug: "test-project" },
          permalink: "https://sentry.io/issues/2"
        }
      ]
    end

    before do
      stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
        .with(
          headers: { "Authorization" => "Bearer #{auth_token}" },
          query: { status: "unresolved", limit: 10 }
        )
        .to_return(status: 200, body: issues_response.to_json)
    end

    it "fetches and formats the issue list correctly" do
      result = server.list_issues(status: "unresolved", limit: 10)
      
      expect(result.issues.length).to eq(2)
      expect(result.total_count).to eq(2)
      
      first_issue = result.issues.first
      expect(first_issue.id).to eq("1")
      expect(first_issue.title).to eq("First Error")
      expect(first_issue.count).to eq(10)
    end

    context "with query parameter" do
      before do
        stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
          .with(
            headers: { "Authorization" => "Bearer #{auth_token}" },
            query: { query: "test", status: "unresolved", limit: 10 }
          )
          .to_return(status: 200, body: "[]")
      end

      it "includes query in the request" do
        result = server.list_issues(query: "test")
        expect(result.issues).to be_empty
        expect(result.total_count).to eq(0)
      end
    end

    context "when API request fails" do
      before do
        stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
          .with(
            headers: {
              "Authorization" => "Bearer #{auth_token}",
              "Content-Type" => "application/json"
            },
            query: {
              status: "unresolved",
              limit: 10
            }
          )
          .to_return(
            status: 500,
            body: { detail: "Internal Server Error" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises an error with context" do
        expect { server.list_issues }
          .to raise_error(RuntimeError, /Failed to list issues: API request failed \(500\): Internal Server Error/)
      end
    end

    context "with time-based filtering" do
      context "using stats_period" do
        before do
          stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
            .with(
              headers: { 
                "Authorization" => "Bearer #{auth_token}",
                "Content-Type" => "application/json"
              },
              query: {
                status: "unresolved",
                limit: 10,
                statsPeriod: "1h"
              }
            )
            .to_return(status: 200, body: issues_response.to_json)
        end

        it "includes stats_period in the request" do
          result = server.list_issues(stats_period: "1h")
          expect(result.issues.length).to eq(2)
        end
      end

      context "using date range" do
        let(:start_date) { "2024-03-14T00:00:00Z" }
        let(:end_date) { "2024-03-14T23:59:59Z" }

        before do
          stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
            .with(
              headers: {
                "Authorization" => "Bearer #{auth_token}",
                "Content-Type" => "application/json"
              },
              query: {
                status: "unresolved",
                limit: 10,
                start: start_date,
                end: end_date
              }
            )
            .to_return(status: 200, body: issues_response.to_json)
        end

        it "includes start and end dates in the request" do
          result = server.list_issues(
            start_date: start_date,
            end_date: end_date
          )
          expect(result.issues.length).to eq(2)
        end

        it "accepts Time objects for dates" do
          start_time = Time.parse(start_date)
          end_time = Time.parse(end_date)
          
          result = server.list_issues(
            start_date: start_time,
            end_date: end_time
          )
          expect(result.issues.length).to eq(2)
        end
      end

      context "using first_seen and last_seen" do
        let(:first_seen) { "2024-03-14T00:00:00Z" }
        let(:last_seen) { "2024-03-14T23:59:59Z" }

        before do
          stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
            .with(
              headers: {
                "Authorization" => "Bearer #{auth_token}",
                "Content-Type" => "application/json"
              },
              query: {
                status: "unresolved",
                limit: 10,
                firstSeen: first_seen,
                lastSeen: last_seen
              }
            )
            .to_return(status: 200, body: issues_response.to_json)
        end

        it "includes first_seen and last_seen in the request" do
          result = server.list_issues(
            first_seen: first_seen,
            last_seen: last_seen
          )
          expect(result.issues.length).to eq(2)
        end
      end

      context "with invalid datetime format" do
        it "raises an error for invalid datetime format" do
          expect {
            server.list_issues(start_date: 123)
          }.to raise_error(ArgumentError, /Invalid datetime format/)
        end
      end

      context "with combined filters" do
        before do
          stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
            .with(
              headers: {
                "Authorization" => "Bearer #{auth_token}",
                "Content-Type" => "application/json"
              },
              query: {
                query: "error",
                status: "unresolved",
                limit: 5,
                statsPeriod: "1h",
                firstSeen: "2024-03-14T00:00:00Z"
              }
            )
            .to_return(status: 200, body: issues_response.to_json)
        end

        it "combines multiple filter parameters" do
          result = server.list_issues(
            query: "error",
            limit: 5,
            stats_period: "1h",
            first_seen: "2024-03-14T00:00:00Z"
          )
          expect(result.issues.length).to eq(2)
        end
      end
    end
  end

  describe "#list_team_issues" do
    let(:team_slug) { "horseshoes" }
    let(:team_projects_response) do
      [
        { "slug" => "project-a" },
        { "slug" => "project-b" }
      ]
    end

    let(:issues_response) do
      [
        {
          id: "1",
          title: "Team Error",
          status: "unresolved",
          level: "error",
          firstSeen: "2024-03-14T00:00:00Z",
          lastSeen: "2024-03-14T01:00:00Z",
          count: "10",
          project: { slug: "project-a" },
          permalink: "https://sentry.io/issues/1"
        }
      ]
    end

    before do
      # Stub team projects request
      stub_request(:get, "#{base_url}/organizations/strongmind-4j/teams/#{team_slug}/projects/")
        .with(
          headers: {
            "Authorization" => "Bearer #{auth_token}",
            "Content-Type" => "application/json"
          }
        )
        .to_return(status: 200, body: team_projects_response.to_json)

      # Stub issues request with project filter
      stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
        .with(
          headers: {
            "Authorization" => "Bearer #{auth_token}",
            "Content-Type" => "application/json"
          },
          query: {
            query: "project:project-a OR project:project-b",
            status: "unresolved",
            limit: 10
          }
        )
        .to_return(status: 200, body: issues_response.to_json)
    end

    it "fetches and formats team issues correctly" do
      result = server.list_team_issues(team_slug: team_slug)
      
      expect(result.issues.length).to eq(1)
      expect(result.total_count).to eq(1)
      
      issue = result.issues.first
      expect(issue.title).to eq("Team Error")
      expect(issue.project).to eq("project-a")
    end

    context "with time-based filtering" do
      before do
        stub_request(:get, "#{base_url}/organizations/strongmind-4j/issues/")
          .with(
            headers: {
              "Authorization" => "Bearer #{auth_token}",
              "Content-Type" => "application/json"
            },
            query: {
              query: "project:project-a OR project:project-b",
              status: "unresolved",
              limit: 10,
              statsPeriod: "24h"
            }
          )
          .to_return(status: 200, body: issues_response.to_json)
      end

      it "combines team and time filters" do
        result = server.list_team_issues(
          team_slug: team_slug,
          stats_period: "24h"
        )
        expect(result.issues.length).to eq(1)
      end
    end

    context "when team has no projects" do
      before do
        stub_request(:get, "#{base_url}/organizations/strongmind-4j/teams/#{team_slug}/projects/")
          .to_return(status: 200, body: [].to_json)
      end

      it "returns empty issue list" do
        result = server.list_team_issues(team_slug: team_slug)
        expect(result.issues).to be_empty
        expect(result.total_count).to eq(0)
      end
    end

    context "when team is not found" do
      before do
        stub_request(:get, "#{base_url}/organizations/strongmind-4j/teams/#{team_slug}/projects/")
          .to_return(status: 404, body: { detail: "Team not found" }.to_json)
      end

      it "raises an error with context" do
        expect { server.list_team_issues(team_slug: team_slug) }
          .to raise_error(/Failed to get team projects/)
      end
    end
  end
end 