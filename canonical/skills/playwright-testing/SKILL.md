---
name: playwright-testing
description: "Playwright E2E testing toolkit with setup scripts, test patterns, and best practice references. Use when setting up Playwright in a project, writing E2E tests, creating page object models, configuring test runners, or troubleshooting Playwright issues. Also trigger when the user mentions browser testing, E2E testing, test automation, or visual regression testing."
---

# Playwright Testing

A toolkit for writing and maintaining Playwright E2E tests. Provides project setup, test patterns, page object model templates, and configuration references.

## When to Use

- Setting up Playwright in a new project
- Writing E2E tests for user workflows
- Creating page object models
- Configuring Playwright for CI/CD
- Debugging flaky tests

## Setup

For new projects, ensure Playwright is installed:

```bash
npm init playwright@latest
```

## Test Patterns

### Page Object Model

Keep selectors and page interactions in page objects, not in test files:

```typescript
// pages/login.page.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Sign in' }).click();
  }
}
```

### Test Structure

```typescript
test.describe('Feature Name', () => {
  test('should [expected behavior] when [condition]', async ({ page }) => {
    // Arrange
    const loginPage = new LoginPage(page);
    await loginPage.goto();

    // Act
    await loginPage.login('user@example.com', 'password');

    // Assert
    await expect(page.getByText('Welcome')).toBeVisible();
  });
});
```

### Selector Priority

1. `getByRole()` — accessible role (button, heading, textbox)
2. `getByLabel()` — form field labels
3. `getByText()` — visible text content
4. `getByTestId()` — data-testid attributes (last resort)

Avoid CSS/XPath selectors — they're brittle.

### Waiting

Never use `waitForTimeout()`. Use:
- `expect(locator).toBeVisible()` — auto-retrying assertion
- `page.waitForURL()` — wait for navigation
- `page.waitForResponse()` — wait for API responses
- `locator.waitFor()` — wait for element state

## CI Configuration

### GitHub Actions

```yaml
- name: Run Playwright tests
  run: npx playwright test
- name: Upload report
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: playwright-report
    path: playwright-report/
```

## Anti-Patterns

- **Shared state between tests**: Each test must be independent
- **Hardcoded waits**: Use Playwright's auto-waiting instead
- **CSS selectors**: Use accessible selectors
- **Testing implementation details**: Test user-visible behavior
- **Giant test files**: Split by feature/workflow
