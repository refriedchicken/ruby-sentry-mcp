# Sentry MCP Tools

This document tracks the implementation status of tools in the Ruby Sentry MCP server.

## Implemented Tools

### get_sentry_issue
- **Status**: ✅ Completed
- **Implementation Date**: March 14, 2024
- **Description**: Retrieves detailed information about a specific Sentry issue by ID or URL
- **Features**:
  - Fetches issue details including title, status, and level
  - Extracts and formats stacktrace information
  - Includes project information and permalink
  - Supports both issue ID and URL inputs

### list_issues
- **Status**: ✅ Completed
- **Implementation Date**: March 14, 2024
- **Description**: Retrieves a list of Sentry issues with pagination support
- **Features**:
  - Configurable limit for number of issues
  - Status filtering (e.g., unresolved)
  - Optional query parameter for filtering
  - Returns total count of matching issues

## Planned Tools

### update_issue
- **Status**: 📋 Planned
- **Priority**: High
- **Description**: Update the status and properties of a Sentry issue
- **Planned Features**:
  - Change issue status (resolve/ignore)
  - Assign issues to team members
  - Add comments or notes
  - Update issue properties

### get_issue_events
- **Status**: 📋 Planned
- **Priority**: High
- **Description**: Retrieve detailed event information for a specific issue
- **Planned Features**:
  - List all occurrences of an issue
  - Include full context and environment data
  - Support pagination for large event lists
  - Filter events by date range

### search_issues
- **Status**: 📋 Planned
- **Priority**: Medium
- **Description**: Advanced issue search with complex filtering
- **Planned Features**:
  - Complex query support
  - Multiple filter combinations
  - Sort and order options
  - Custom search fields

### get_project_stats
- **Status**: 📋 Planned
- **Priority**: Medium
- **Description**: Retrieve statistical data about a Sentry project
- **Planned Features**:
  - Error frequency metrics
  - User impact statistics
  - Resolution time tracking
  - Trend analysis

### get_release_info
- **Status**: 📋 Planned
- **Priority**: Medium
- **Description**: Access release-specific information and issues
- **Planned Features**:
  - Release health metrics
  - Issues introduced in release
  - Regression tracking
  - Deploy and version information

### get_issue_comments
- **Status**: 📋 Planned
- **Priority**: Low
- **Description**: Retrieve comments and discussion history for issues
- **Planned Features**:
  - Comment thread retrieval
  - Author information
  - Timestamp tracking
  - Activity history

### get_user_feedback
- **Status**: 📋 Planned
- **Priority**: Low
- **Description**: Access user-reported feedback on issues
- **Planned Features**:
  - User comments and reports
  - Impact assessment
  - Satisfaction metrics
  - User environment data

### get_organization_stats
- **Status**: 📋 Planned
- **Priority**: Low
- **Description**: Organization-wide statistics and metrics
- **Planned Features**:
  - Cross-project metrics
  - Team performance stats
  - Issue resolution trends
  - Resource utilization data

## Contributing

When implementing a new tool:
1. Update this document with implementation date
2. Move tool from "Planned" to "Implemented"
3. Add any additional features that were implemented
4. Update status to ✅ Completed 