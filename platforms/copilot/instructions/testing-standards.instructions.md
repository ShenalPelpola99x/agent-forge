---
description: "Testing conventions and standards for all test types"
applyTo: "**/*.test.*,**/*.spec.*,**/__tests__/**"
---

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

