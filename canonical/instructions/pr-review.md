---
name: pr-review
description: "Pull request review guidelines and standards"
applyTo: ""
---

# PR Review Guidelines

## Review Checklist

### Correctness
- [ ] Does the code do what the PR description claims?
- [ ] Are edge cases handled (null, empty, boundary values)?
- [ ] Are error scenarios handled gracefully?
- [ ] Is the logic correct for concurrent/async scenarios?

### Security
- [ ] No SQL injection, XSS, or CSRF vulnerabilities
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Input is validated and sanitized
- [ ] Authentication and authorization checks in place
- [ ] No sensitive data in logs or error messages

### Performance
- [ ] No N+1 queries or unnecessary database calls
- [ ] No blocking calls on async paths
- [ ] Appropriate use of caching where beneficial
- [ ] No unnecessary memory allocations in hot paths

### Maintainability
- [ ] Code is readable without comments explaining "what"
- [ ] Follows project naming conventions
- [ ] No duplicated logic — extracted to shared utilities
- [ ] Single responsibility — each class/function does one thing
- [ ] Appropriate error messages for debugging

### Testing
- [ ] New code has tests
- [ ] Tests cover happy path and error cases
- [ ] Tests are independent and don't rely on execution order
- [ ] No flaky test patterns (shared state, timing dependencies)

### Scope
- [ ] Changes match the PR description / linked issue
- [ ] No unrelated changes bundled in
- [ ] PR is appropriately sized (< 400 lines preferred)

## Feedback Format

Use this severity scale:
- **🔴 Critical**: Must fix before merge (bugs, security issues, data loss risks)
- **🟡 Warning**: Should fix, but not a blocker (performance, maintainability)
- **🟢 Suggestion**: Optional improvement (style, alternative approach)
- **💬 Question**: Seeking clarification, not requesting a change

## Tone

- Be constructive — suggest solutions, not just problems
- Explain why — "This could cause X because Y" not just "Don't do this"
- Acknowledge good work — call out clever solutions or thorough testing
- Ask questions instead of making assumptions about intent
