# Ruby Sentry MCP

A Model Context Protocol server for retrieving and analyzing issues from Sentry.io. This server provides tools to inspect error reports, stacktraces, and other debugging information from your Sentry account.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-sentry-mcp'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install ruby-sentry-mcp
```

## Usage

### Starting the Server

To start the MCP server:

```bash
$ ruby-sentry-mcp start --auth-token YOUR_SENTRY_TOKEN
```

Optional parameters:
- `--port PORT` - Port to run the server on (default: 3000)

### Configuration

#### With Claude Desktop

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "sentry": {
      "command": "ruby-sentry-mcp",
      "args": ["start", "--auth-token", "YOUR_SENTRY_TOKEN"]
    }
  }
}
```

#### With Zed

Add to your Zed settings.json:

```json
{
  "context_servers": {
    "mcp-server-sentry": {
      "command": "ruby-sentry-mcp",
      "args": ["start", "--auth-token", "YOUR_SENTRY_TOKEN"]
    }
  }
}
```

### Available Tools

1. `get_sentry_issue`
   - Retrieve and analyze a Sentry issue by ID or URL
   - Input:
     - `issue_id_or_url` (string): Sentry issue ID or URL to analyze
   - Returns: Issue details including:
     - Title
     - Issue ID
     - Status
     - Level
     - First seen timestamp
     - Last seen timestamp
     - Event count
     - Full stacktrace

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mikebenner/ruby-sentry-mcp. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of Conduct

Everyone interacting in the Ruby Sentry MCP project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
