---
name: plan-sprint
description: "Plan a sprint by selecting items from the backlog, estimating effort, and creating a balanced sprint plan"
---

# Plan Sprint

Create a sprint plan from the current backlog.

## Instructions

1. Review the current backlog (open issues, PRs, and milestones)
2. Identify items ready for development (have acceptance criteria, no blockers)
3. Estimate effort for each item (XS/S/M/L/XL)
4. Balance the sprint based on available capacity
5. Identify dependencies and sequencing
6. Output the sprint plan

## Sprint Plan Template

```markdown
## Sprint [N]: [Sprint Goal]

**Duration**: [Start Date] — [End Date]
**Capacity**: [X story points / Y developer-days]

### Sprint Goal
[One-sentence description of what this sprint aims to achieve]

### Committed Items

| # | Issue | Type | Effort | Assignee | Dependencies |
|---|-------|------|--------|----------|-------------|
| 1 | [Title] (#issue) | feature | M | — | — |
| 2 | [Title] (#issue) | bug | S | — | #1 |
| 3 | [Title] (#issue) | task | XS | — | — |

**Total effort**: [X points]

### Stretch Goals
Items to pull in if capacity allows:
- [Title] (#issue) — [Effort]

### Risks
| Risk | Mitigation |
|------|------------|
| [Risk description] | [Mitigation plan] |

### Dependencies
- [External dependency and expected resolution]
```

## Effort Scale

- **XS** (< half day): Config changes, copy updates, simple fixes
- **S** (half day - 1 day): Single-file changes, simple features
- **M** (1-3 days): Multi-file features, API endpoints with tests
- **L** (3-5 days): Cross-cutting features, complex logic
- **XL** (> 1 week): Should be broken down further before committing
