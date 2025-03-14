# Ruby Sentry MCP

A Ruby implementation of the Model Context Protocol (MCP) server for Sentry integration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-sentry-mcp'
```

And then execute:

```bash
$ bundle install
```

## Usage

Start the MCP server:

```bash
$ bundle exec ruby-sentry-mcp start --auth-token YOUR_SENTRY_TOKEN
```

## Development Guidelines

### Running Tests

To run the test suite:

```bash
$ bundle install
$ bundle exec rake spec
```

To run specific tests:

```bash
$ bundle exec rspec spec/ruby/sentry/mcp/server_spec.rb                 # Run all server specs
$ bundle exec rspec spec/ruby/sentry/mcp/server_spec.rb:42             # Run specific test at line 42
$ bundle exec rspec --tag focus                                        # Run only focused specs
```

### Adding or Updating Tools

1. Update `TOOLS.md`:
   - Move tool from "Planned" to "Implemented" section
   - Add implementation date
   - Update status to ✅ Completed
   - List all implemented features

2. Testing Requirements:
   - All tools must have corresponding tests in `spec/ruby/sentry/mcp/`
   - Tests should cover:
     - Success cases with mock responses
     - Error handling
     - Parameter validation
     - Response formatting
   - Use RSpec and WebMock for HTTP request mocking

3. Documentation:
   - Update method documentation with YARD format
   - Include example usage in comments
   - Document all parameters and return values

### Commit Message Format

All commit messages must be written in the style of a sea shanty and follow this format:

```
($TYPE) $SHANTY_TITLE

[Sea shanty verses about the changes]

* Bullet points of specific changes
* More specific changes
* etc.

```

Where:
- `$TYPE` is one of:
  - B: Behavioral (system behavior changes)
  - S: Structural (refactoring)
  - T: Testing (spec changes)
- `$SHANTY_TITLE` is a sea shanty themed title for the changes

Example:
```
(B) Yo Ho Ho, A New Tool Sets Sail!

Hear ye, hear ye, developers true,
A new Sentry tool is coming through!
With tests so strong and docs so clear,
This code will bring us all good cheer!

* Added new tool functionality
* Implemented comprehensive tests
* Updated documentation
* Added error handling
```

## Contributing

1. Create a new branch or fork the repository
2. Make your changes following the guidelines above
3. Add tests for any new functionality
4. Update TOOLS.md if adding/modifying tools
5. Create a pull request with a sea shanty commit message

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby Sentry MCP project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
