# Best Practices for Agent Creation

Consolidated from official documentation for GitHub Copilot, Claude Code, and OpenAI Codex.

---

## Table of Contents

1. [Agent Design Principles](#1-agent-design-principles)
2. [System Prompt Writing](#2-system-prompt-writing)
3. [Tool Configuration](#3-tool-configuration)
4. [Model Selection](#4-model-selection)
5. [Platform-Specific Guidance](#5-platform-specific-guidance)
6. [Testing & Evaluation](#6-testing--evaluation)
7. [Subagent Orchestration](#7-subagent-orchestration)
8. [Distribution & Sharing](#8-distribution--sharing)
9. [Security](#9-security)

---

## 1. Agent Design Principles

### Single Responsibility
Each agent should have one clear role. An agent that tries to do everything (review code AND deploy AND write tests AND manage issues) will do none of them well. Split into focused specialists.

**Good**: "QA testing specialist — writes and runs Playwright E2E tests"
**Bad**: "General-purpose coding assistant that can test, deploy, and review"

### Minimal Tool Set
Only grant the tools the agent's role requires. Excess tools dilute focus and increase the chance of unintended actions.

- Read-only agents: only `read`, `search`, `grep`
- Code writers: add `edit`, `create`
- DevOps agents: add `execute` for terminal commands
- QA agents: add MCP tools like `playwright`

### Clear Boundaries
Define what the agent should NOT do. This is as important as defining what it should do.

```markdown
## Constraints
- Do NOT modify production configuration files
- Do NOT commit or push to git
- Do NOT install packages without user approval
- If a task is outside your expertise, say so rather than guessing
```

### Keyword-Rich Descriptions
The description field is the primary trigger mechanism for auto-delegation. Include action verbs, domain nouns, and common user phrases.

**Good**: "Playwright E2E testing specialist. Use when writing browser tests, debugging test failures, analyzing test coverage, creating page object models, or setting up test infrastructure. Triggers on mentions of Playwright, E2E, end-to-end, browser testing, or test automation."

**Bad**: "A helpful testing agent."

### Proactive Descriptions
Use "use when..." or "use proactively" phrasing to encourage auto-delegation.

---

## 2. System Prompt Writing

### Imperative Form
Write instructions as commands, not suggestions.

**Good**: "Review the PR diff for security vulnerabilities. Flag any SQL injection, XSS, or authentication bypass risks."
**Bad**: "You should try to look at the PR diff and see if there might be any security issues."

### Context Economy
Only include information the model doesn't already know. Don't explain what HTTP is, how git works, or basic programming concepts.

### Consistent Terminology
Pick one term for each concept and use it throughout. Don't alternate between "field", "box", "input", and "element" for the same thing.

### Show Don't Tell
Use concrete examples rather than abstract descriptions.

**Good**:
```
## Commit Message Format
feat(auth): implement JWT-based authentication
fix(api): handle null response from payment gateway
```

**Bad**: "Write commit messages following conventional commits format with proper scoping."

### Degrees of Freedom
Match instruction specificity to task fragility:
- **Fragile tasks** (deployments, data migrations): Give exact steps, explicit commands
- **Flexible tasks** (code review, research): Give direction and criteria, let the agent decide approach

### Structure
Use clear markdown sections. A well-structured agent body typically has:
1. Role — What this agent is
2. Responsibilities — What it does (numbered list)
3. Approach — How it works through tasks
4. Constraints — What it must not do
5. Output format — Expected output structure (if applicable)

---

## 3. Tool Configuration

### Copilot Tool Aliases
```yaml
tools:
  - read        # Read files
  - edit        # Edit files
  - search      # Semantic search
  - execute     # Run terminal commands
  - agent       # Spawn subagents
  - web         # Web search
  - todo        # Manage todo lists
  - "mcp:server_name/*"  # All tools from an MCP server
  - "mcp:server_name/specific_tool"  # Single MCP tool
```

### Claude Code Tools
In Claude Code agent files, specify tools in a `## Tools` section or use `allowedTools` / `disallowedTools` in settings:
```
## Tools
- Read, Grep, Glob — for code analysis
- Write, Edit — for code changes
- Bash — for running tests
- Agent(qa-tester) — for delegating test tasks
```

### Denylist Pattern
When an agent needs most tools but should be blocked from a few, use a denylist:
```json
{
  "disallowedTools": ["Write", "Edit", "Bash"]
}
```

### MCP Scoping
Scope MCP servers to specific agents to avoid context bloat. Not every agent needs access to every MCP server.

---

## 4. Model Selection

| Model | Best For | Examples |
|-------|----------|---------|
| **Opus** | Complex reasoning, architecture decisions, nuanced review | Backend-developer, agent-composer |
| **Sonnet** | Balanced tasks, most agent work | QA-tester, devops, project-manager |
| **Haiku** | Fast read-only tasks, simple queries | Read-only researchers, quick lookups |

### Copilot Model Syntax
```yaml
model: sonnet    # Single model
model:           # Fallback chain
  - sonnet
  - gpt-4o
```

### Claude Code Model Syntax
Specify in the agent file body or let the user's default apply.

---

## 5. Platform-Specific Guidance

### GitHub Copilot
- YAML frontmatter is **required** (`description`, optionally `tools`, `model`, `agents`)
- Prompt limit: ~30K characters
- `target` field restricts environment: `target: vscode` or `target: terminal`
- Skills use `SKILL.md` with `name` and `description` in frontmatter
- Instructions use `applyTo` to auto-attach to file patterns
- Agents listed in `agents:` frontmatter can be spawned as subagents

### Claude Code
- No frontmatter — conventions are in the body
- Supports hooks (PreToolUse, PostToolUse) for validation
- Persistent memory with user/project/local scopes
- Process isolation via worktrees
- Fork mode for parallel exploration
- MCP server scoping per agent
- `allowedTools` and `disallowedTools` for fine-grained control

### OpenAI Codex
- Single `AGENTS.md` file in repo root
- Keep content focused and scannable
- No separate agent files — sections within the single file
- No tool configuration — Codex determines tool use from context

---

## 6. Testing & Evaluation

### Verification Criteria
Give agents testable success criteria. After creating an agent, ask:
- "Can I tell if this worked by looking at the output?"
- "What does success look like?"

### Writer/Reviewer Pattern
Use one session to create the agent, a fresh session to test it. The fresh session won't have your creation context, simulating how the agent will actually be used.

### Eval-Driven Development
Build test cases BEFORE extensive documentation:
1. Write 2-3 representative prompts
2. Run with and without the agent
3. Compare results
4. Iterate on the agent definition

### Cross-Platform Testing
Test agents on at least 2 platforms (typically Copilot + Claude Code) to catch format-specific issues:
- Does the agent stay in role?
- Are tool restrictions respected?
- Does auto-delegation work?

---

## 7. Subagent Orchestration

### Context Isolation
Subagents start with fresh context. They don't see the parent's conversation history. Include all necessary context in the delegation prompt.

### Delegation Patterns
- **Automatic**: Description-based (platform matches user request to agent descriptions)
- **Explicit**: User @-mentions the agent or uses `--agent` flag

### Common Patterns
- **Parallel research**: Spawn multiple read-only subagents for independent investigations
- **Chain**: Sequential calls, each building on previous results
- **Coordinator**: A parent agent routes tasks to specialists
- **Review**: One agent creates, another reviews

### Constraints
- Subagents cannot spawn other subagents (Claude Code limitation)
- Keep delegation prompts focused — don't dump entire conversation
- Set clear return criteria ("Return when you've found X" or "Return a summary of Y")

---

## 8. Distribution & Sharing

| Platform | Personal | Workspace | Team |
|----------|----------|-----------|------|
| Copilot | `%APPDATA%\Code\User\prompts\` | `.github/agents/` | Git submodule |
| Claude Code | `~/.claude/agents/` | `.claude/agents/` | Git submodule |
| Codex | N/A | `AGENTS.md` | In repo |

### Cross-Platform Distribution
Use a canonical source → platform build pipeline to maintain consistency across all platforms without duplicating content.

---

## 9. Security

- **Audit before installing**: Always read agent/skill contents from untrusted sources
- **No secrets**: Never embed API keys, tokens, or credentials in agent files
- **Permission modes**: Use appropriate permission level (Claude Code: default, acceptEdits, auto, plan)
- **Hook validation**: Use PreToolUse hooks to validate commands before execution (Claude Code)
- **Minimal permissions**: Don't give write access to read-only agents
