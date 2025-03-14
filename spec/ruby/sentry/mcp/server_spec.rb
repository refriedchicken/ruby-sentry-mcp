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
  end
end 