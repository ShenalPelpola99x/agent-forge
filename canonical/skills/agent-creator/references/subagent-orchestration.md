# Subagent Orchestration Guide

How to design agents that delegate to other agents across platforms.

---

## Core Concepts

### Context Isolation
Subagents start with a **fresh context**. They do not inherit the parent agent's conversation history, tool outputs, or working state. This means:
- Include all relevant context in the delegation prompt
- Don't assume the subagent knows what you've already discussed
- Be explicit about what you want returned

### Delegation Prompt Pattern
When delegating to a subagent, structure the handoff:
```
Analyze the test coverage in src/components/. Focus on:
1. Which components have no tests
2. Which components have tests but low branch coverage
3. Suggest specific test cases for the top 3 gaps

Return a markdown table with component name, current coverage %, and suggested tests.
```

---

## Delegation Patterns

### 1. Parallel Research
Spawn multiple read-only subagents for independent investigations, then synthesize results.

```
Parent (coordinator):
  → Subagent A: "Analyze the frontend architecture"
  → Subagent B: "Analyze the backend API structure"  
  → Subagent C: "Analyze the CI/CD pipeline"
  ← Synthesize all three reports into a unified assessment
```

Best for: codebase analysis, multi-domain research, large-scale audits.

### 2. Chain Pattern
Sequential subagent calls where each builds on the previous result.

```
Parent:
  → Subagent A: "Find all public API endpoints" → returns list
  → Subagent B: "Write integration tests for these endpoints: [list]" → returns tests
  → Subagent C: "Review these tests for edge cases: [tests]" → returns review
```

Best for: multi-step workflows, pipelines, progressive refinement.

### 3. Coordinator Pattern
A parent agent that routes incoming tasks to the right specialist.

```
Parent (project-manager):
  User: "I need tests for the auth module"
  → Routes to: qa-tester
  
  User: "Deploy the latest changes to staging"
  → Routes to: devops
  
  User: "Review this PR"
  → Routes to: backend-developer
```

Best for: meta-agents, project managers, team leads.

### 4. Review Pattern
One agent creates, another reviews.

```
Parent:
  → Subagent A (backend-developer): "Implement the user service"
  → Subagent B (qa-tester): "Review this implementation for testability"
```

Best for: code quality, security review, design review.

---

## Platform-Specific Configuration

### Copilot
```yaml
# In the parent agent's frontmatter:
agents:
  - qa-tester
  - backend-developer
  - devops
tools:
  - agent  # Required to enable subagent spawning
```

The parent can then delegate with `@qa-tester` or the platform may auto-delegate based on task description matching agent descriptions.

### Claude Code
```markdown
## Tools
- Agent(qa-tester, backend-developer, devops)
```

Or use unrestricted delegation:
```markdown
## Tools
- Agent
```

Claude Code subagents can run in foreground (blocking) or background (concurrent).

### Codex / Cursor / Windsurf
These platforms don't have native subagent support. For these, include all personas in the single instruction file and let the model switch between roles internally.

---

## Anti-Patterns in Orchestration

### Circular Handoffs
**Bad**: Agent A delegates to Agent B, which delegates back to Agent A.
**Fix**: Include a progress criterion — "Only delegate if you cannot handle this task yourself."

### Over-Delegation
**Bad**: Parent delegates every single line of work, doing nothing itself.
**Fix**: Parent should handle coordination, synthesis, and simple tasks directly.

### Context Dumping
**Bad**: Passing the entire conversation history to a subagent.
**Fix**: Summarize the relevant context and be specific about what's needed.

### Infinite Delegation Depth
**Note**: Claude Code subagents cannot spawn other subagents. This is a hard constraint, not a bug. Design your hierarchy with max 2 levels: coordinator → specialist.
