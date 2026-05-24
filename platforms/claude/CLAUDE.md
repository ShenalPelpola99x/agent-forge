# Project Instructions

## dotnet-backend

---
name: dotnet-backend
description: ".NET backend coding standards and conventions"
applyTo: "**/*.cs"
---

# .NET Backend Coding Standards

## Naming Conventions

- **Classes/Interfaces**: PascalCase (`OrderService`, `IOrderRepository`)
- **Methods**: PascalCase (`GetOrderByIdAsync`)
- **Properties**: PascalCase (`TotalAmount`)
- **Private fields**: `_camelCase` (`_orderRepository`)
- **Parameters/locals**: camelCase (`orderId`)
- **Constants**: PascalCase (`MaxRetryCount`)
- **Async methods**: Suffix with `Async` (`GetOrderAsync`)

## Code Organization

- One class per file (except small related types)
- File name matches class name
- Use file-scoped namespaces (`namespace MyApp.Services;`)
- Order members: fields â†’ constructors â†’ public methods â†’ private methods
- Use primary constructors for DI when appropriate

## Error Handling

- Use global exception middleware â€” don't scatter try/catch
- Throw specific exceptions (`NotFoundException`, `ValidationException`)
- Never catch `Exception` silently â€” always log or rethrow
- Use `Result<T>` pattern for expected failures, exceptions for unexpected ones
- Always include context in exception messages

## Async Patterns

- Always use `async`/`await` â€” never `.Result` or `.Wait()`
- Use `ConfigureAwait(false)` in library code
- Return `Task` not `void` from async methods
- Use `CancellationToken` on all I/O-bound operations
- Use `ValueTask<T>` for hot paths that often complete synchronously

## API Design

- Use proper HTTP verbs: GET (read), POST (create), PUT (replace), PATCH (update), DELETE (remove)
- Return appropriate status codes (200, 201, 204, 400, 404, 409, 500)
- Use DTOs for request/response â€” never expose entities
- Validate input with FluentValidation or data annotations
- Version APIs when breaking changes are needed

## Dependency Injection

- Register services in `Program.cs` or extension methods
- Use constructor injection â€” avoid service locator pattern
- Scoped lifetime for request-scoped services (DbContext)
- Singleton lifetime for stateless services
- Transient lifetime for lightweight, stateless utilities

## EF Core

- Use migrations for all schema changes
- Use Fluent API configuration in separate `IEntityTypeConfiguration<T>` classes
- Use `AsNoTracking()` for read-only queries
- Use projection (`Select`) to load only needed columns
- Avoid N+1 â€” use `Include()` or split queries


---

## pr-review

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
- [ ] No duplicated logic â€” extracted to shared utilities
- [ ] Single responsibility â€” each class/function does one thing
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
- **ðŸ”´ Critical**: Must fix before merge (bugs, security issues, data loss risks)
- **ðŸŸ¡ Warning**: Should fix, but not a blocker (performance, maintainability)
- **ðŸŸ¢ Suggestion**: Optional improvement (style, alternative approach)
- **ðŸ’¬ Question**: Seeking clarification, not requesting a change

## Tone

- Be constructive â€” suggest solutions, not just problems
- Explain why â€” "This could cause X because Y" not just "Don't do this"
- Acknowledge good work â€” call out clever solutions or thorough testing
- Ask questions instead of making assumptions about intent


---

## testing-standards

---
name: testing-standards
description: "Testing conventions and standards for all test types"
applyTo: "**/*.test.*,**/*.spec.*,**/__tests__/**"
---

# Testing Standards

## Test Structure

Follow Arrange-Act-Assert (AAA) pattern:

```
// Arrange â€” set up test data and dependencies
// Act â€” execute the operation under test
// Assert â€” verify the expected outcome
```

## Naming Convention

Use descriptive names that explain the scenario:

```
should_[expectedBehavior]_when_[condition]
```

Examples:
- `should_return_404_when_order_not_found`
- `should_calculate_total_with_discount_when_coupon_applied`
- `should_throw_validation_error_when_email_is_empty`

## Test Independence

- Each test must be independent â€” no shared mutable state
- Use fresh fixtures/setup for each test
- Tests must pass in any order
- Clean up resources in teardown/afterEach

## Test Types

### Unit Tests
- Test a single function/method in isolation
- Mock external dependencies
- Fast â€” should run in milliseconds
- Cover happy path, edge cases, error cases

### Integration Tests
- Test interaction between components
- Use real dependencies where practical (test database, test API)
- May use `WebApplicationFactory` for .NET API tests
- Slower â€” acceptable to run in seconds

### E2E Tests
- Test complete user workflows through the UI
- Use Playwright or equivalent browser automation
- Slowest â€” run in CI, not on every save
- Focus on critical paths, not exhaustive coverage

## Coverage Guidelines

- Aim for 80%+ line coverage on business logic
- 100% coverage is not a goal â€” diminishing returns
- Cover: happy path, error cases, edge cases, boundary values
- Don't test: framework code, simple getters/setters, generated code

## Assertions

- One logical assertion per test (multiple assertions for one concept is fine)
- Use specific assertions (`toEqual`, `toContain`) not generic (`toBeTruthy`)
- Assert on behavior, not implementation details
- Test what the user sees, not internal state

## Mocking

- Mock at service boundaries (HTTP, DB, file system)
- Don't mock the thing you're testing
- Prefer fakes over mocks when the interface is simple
- Verify mock interactions only when the side effect IS the behavior


---


