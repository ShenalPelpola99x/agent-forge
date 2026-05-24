# Platform Format Reference

Quick reference for all 5 platform agent file formats.

---

## GitHub Copilot (.agent.md)

**Location**: `.github/agents/<name>.agent.md` (workspace) or `%APPDATA%\Code\User\prompts\<name>.agent.md` (personal)

**Format**:
```markdown
---
description: "50-word description with trigger phrases"
tools:
  - read
  - edit
  - search
  - execute
  - "mcp:playwright/*"
model: sonnet
agents:
  - qa-tester
  - backend-developer
---

# Agent Display Name

System prompt / instructions body goes here.

## Role
What this agent does.

## Responsibilities
1. First task
2. Second task

## Constraints
- Do NOT do X
```

**Required frontmatter**: `description`
**Optional frontmatter**: `tools`, `model`, `agents`, `target`

**Tool aliases**: `read`, `edit`, `search`, `execute`, `agent`, `web`, `todo`
**MCP tools**: `"mcp:server_name/*"` or `"mcp:server_name/tool_name"`
**Model**: String or array for fallback chain

---

## Claude Code (.claude/agents/*.md)

**Location**: `.claude/agents/<name>.md` (workspace) or `~/.claude/agents/<name>.md` (personal)

**Format**:
```markdown
# Agent Display Name

System prompt / instructions body goes here.

## Role
What this agent does.

## Tools
- Read, Grep, Glob
- Write, Edit
- Bash
- Agent(subagent-name)

## Model
sonnet

## Constraints
- Do NOT do X
```

**No YAML frontmatter** — all configuration is in the body using markdown sections.

**Tool names**: Read, Write, Edit, Bash, Grep, Glob, Agent, WebSearch
**Subagent restriction**: `Agent(name1, name2)` limits which subagents can be spawned
**Settings**: `.claude/settings.json` can define `allowedTools` and `disallowedTools`

---

## OpenAI Codex (AGENTS.md)

**Location**: `AGENTS.md` in repo root

**Format**:
```markdown
# Project Agents

## QA Tester

You are a QA testing specialist...

### Responsibilities
1. Write E2E tests
2. Analyze coverage

### Constraints
- Do not modify production code

---

## DevOps Engineer

You are a DevOps specialist...
```

**No frontmatter**. **No tool configuration**. **No model selection**.
All agents go in a single file, separated by `---` or `##` headings.
Keep content scannable — Codex parses the entire file.
Use `## Agent: <Name>` sections to define different agent personas.
