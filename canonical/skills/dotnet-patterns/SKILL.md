---
name: dotnet-patterns
description: ".NET architecture patterns and best practices reference. Use when designing .NET service architectures, implementing repository patterns, configuring Entity Framework Core, applying SOLID principles, setting up clean architecture, or reviewing .NET code for pattern violations. Also trigger when the user mentions CQRS, MediatR, Fluent Validation, AutoMapper, or middleware in a .NET context."
---

# .NET Patterns

Reference for .NET architecture patterns, clean architecture setup, and Entity Framework Core best practices.

## When to Use

- Designing a new .NET service or API
- Implementing repository, CQRS, or mediator patterns
- Configuring Entity Framework Core
- Reviewing code for SOLID violations
- Setting up dependency injection

## Clean Architecture

### Layer Structure

```
src/
├── Domain/                 # Entities, value objects, domain events
│   ├── Entities/
│   ├── ValueObjects/
│   └── Events/
├── Application/            # Use cases, interfaces, DTOs
│   ├── Commands/
│   ├── Queries/
│   ├── Interfaces/
│   └── DTOs/
├── Infrastructure/         # EF Core, external services, file I/O
│   ├── Data/
│   ├── Repositories/
│   └── Services/
└── API/                    # Controllers, middleware, startup
    ├── Controllers/
    ├── Middleware/
    └── Filters/
```

### Dependency Rule

Dependencies point inward: API → Application → Domain. Infrastructure implements Application interfaces.

```
API → Application ← Infrastructure
              ↓
           Domain
```

## Entity Framework Core

### DbContext Configuration

```csharp
public class AppDbContext : DbContext
{
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}
```

### Entity Configuration (Fluent API)

```csharp
public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.HasKey(o => o.Id);
        builder.Property(o => o.Total).HasPrecision(18, 2);
        builder.HasMany(o => o.Items).WithOne().HasForeignKey(i => i.OrderId);
    }
}
```

### Query Patterns

```csharp
// Read-only queries — use AsNoTracking
var orders = await context.Orders
    .AsNoTracking()
    .Where(o => o.Status == OrderStatus.Active)
    .Select(o => new OrderDto(o.Id, o.Total, o.CreatedAt))
    .ToListAsync();

// Avoid N+1 — use Include or projection
var order = await context.Orders
    .Include(o => o.Items)
    .FirstOrDefaultAsync(o => o.Id == id);
```

## Repository Pattern

```csharp
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(int id);
    Task<IReadOnlyList<T>> GetAllAsync();
    Task<T> AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(T entity);
}
```

Use repositories for domain entities. Use EF Core directly for simple queries that don't need abstraction.

## CQRS with MediatR

```csharp
// Command
public record CreateOrderCommand(string CustomerId, List<OrderItemDto> Items) : IRequest<int>;

// Handler
public class CreateOrderHandler : IRequestHandler<CreateOrderCommand, int>
{
    public async Task<int> Handle(CreateOrderCommand request, CancellationToken ct)
    {
        // Business logic here
    }
}

// Query
public record GetOrderQuery(int Id) : IRequest<OrderDto>;
```

Use CQRS only when complexity warrants it. Simple CRUD doesn't need MediatR.

## SOLID Quick Reference

| Principle | Violation Sign | Fix |
|-----------|---------------|-----|
| **S**ingle Responsibility | Class has 10+ methods across different concerns | Split into focused classes |
| **O**pen/Closed | Switch/if chains for each new type | Use polymorphism or strategy pattern |
| **L**iskov Substitution | Subclass throws NotImplementedException | Redesign hierarchy |
| **I**nterface Segregation | Interface has 15 methods, implementors stub half | Split into smaller interfaces |
| **D**ependency Inversion | `new ConcreteService()` in business logic | Inject interface via constructor |

## Anti-Patterns

- **Anemic domain model**: Entities with only properties, logic in services
- **Fat controllers**: Business logic in controllers instead of services
- **Repository over repository**: Wrapping EF Core in a generic repo that just delegates
- **async void**: Always return `Task` — `async void` swallows exceptions
- **God DbContext**: One DbContext with 50 DbSets — use bounded contexts
