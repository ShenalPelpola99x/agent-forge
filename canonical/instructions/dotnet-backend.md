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
- Order members: fields → constructors → public methods → private methods
- Use primary constructors for DI when appropriate

## Error Handling

- Use global exception middleware — don't scatter try/catch
- Throw specific exceptions (`NotFoundException`, `ValidationException`)
- Never catch `Exception` silently — always log or rethrow
- Use `Result<T>` pattern for expected failures, exceptions for unexpected ones
- Always include context in exception messages

## Async Patterns

- Always use `async`/`await` — never `.Result` or `.Wait()`
- Use `ConfigureAwait(false)` in library code
- Return `Task` not `void` from async methods
- Use `CancellationToken` on all I/O-bound operations
- Use `ValueTask<T>` for hot paths that often complete synchronously

## API Design

- Use proper HTTP verbs: GET (read), POST (create), PUT (replace), PATCH (update), DELETE (remove)
- Return appropriate status codes (200, 201, 204, 400, 404, 409, 500)
- Use DTOs for request/response — never expose entities
- Validate input with FluentValidation or data annotations
- Version APIs when breaking changes are needed

## Dependency Injection

- Register services in `Program.cs` or extension methods
- Use constructor injection — avoid service locator pattern
- Scoped lifetime for request-scoped services (DbContext)
- Singleton lifetime for stateless services
- Transient lifetime for lightweight, stateless utilities

## EF Core

- Use migrations for all schema changes
- Use Fluent API configuration in separate `IEntityTypeConfiguration<T>` classes
- Use `AsNoTracking()` for read-only queries
- Use projection (`Select`) to load only needed columns
- Avoid N+1 — use `Include()` or split queries
