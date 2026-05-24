---
name: agent-creator
description: "Create high-quality custom agents and subagents for multiple AI platforms (VS Code Copilot, Claude Code, OpenAI Codex). Use this skill whenever the user wants to create a new agent, design a subagent, build an agent hierarchy, convert an agent between platforms, or improve an existing agent definition. Also trigger when the user mentions custom agents, agent profiles, subagent configuration, agent.md files, multi-platform agent deployment, or says things like 'I need an agent for...', 'create an agent that...', 'build me an agent'. Even if the user doesn't say 'agent' explicitly but describes a specialized AI persona or coding assistant role, use this skill."
---

# Agent Creator

Create custom agents for 3 AI platforms from a single canonical source. Follows a canonical-first architecture: author once, generate platform-specific outputs for Copilot, Claude Code, and Codex.

## Workflow

### Step 1: Capture Intent

Determine how the user wants to proceed:

**Option A — Interview (default):** Ask these questions:
1. What role should this agent fill? (e.g., code reviewer, DevOps engineer, QA tester)
2. What specific tasks should it handle? List 3-5 core responsibilities
3. What tools does it need? (file read/write, terminal, browser, MCP servers, subagents)
4. What should it NOT do? (boundaries and constraints)
5. Which platforms do you need? (copilot, claude, codex, or all)
6. Should it delegate to subagents? If so, which ones?
7. Any model preference? (opus for complex reasoning, sonnet for balanced, haiku for fast tasks)

**Option B — Template:** Let the user pick a starting template from `templates/`. Available templates:
- `code-reviewer.md` — Code review specialist
- `testing-specialist.md` — QA / testing agent
- `devops.md` — DevOps lifecycle agent
- `domain-expert.md` — Domain-specific specialist
- `coordinator.md` — Orchestrator that delegates to subagents
- `read-only-researcher.md` — Read-only research/exploration agent

### Step 2: Research

Before writing the agent, gather context:
- Explore the user's codebase for conventions, tech stack, existing agents
- Check for naming conflicts with existing agents
- Identify MCP servers that would be useful
- Review `references/best-practices.md` for design guidance

### Step 3: Design the Agent

Based on intent + research, design the agent profile:
- **Name**: kebab-case identifier (e.g., `qa-tester`)
- **Persona**: One-sentence role description
- **Responsibilities**: 3-7 specific tasks
- **Tools**: Minimal set needed for the role
- **Constraints**: What the agent must NOT do
- **Model**: Recommended model tier
- **Subagents**: Which agents it can delegate to (if any)
- **Required Skills**: Skills this agent depends on
- **Required MCP**: MCP servers needed

Present the design to the user for approval before writing.

### Step 4: Write the Canonical Agent File

Write the agent in canonical format (platform-agnostic markdown). Save to `canonical/agents/<name>.md`.

**Canonical format:**

```markdown
---
name: <kebab-case-name>
version: 1.0.0
description: "<50-word description with trigger phrases>"
persona: "<one-sentence role>"
tools:
  - read
  - edit
  - search
  - execute
model: sonnet
subagents: []
requires_skills: []
requires_mcp: []
tags:
  - <tag1>
  - <tag2>
---

# <Agent Display Name>

<System prompt / instructions body>

## Role

<What this agent does — imperative form>

## Responsibilities

1. <First responsibility>
2. <Second responsibility>
...

## Approach

<How the agent should work through tasks>

## Constraints

- Do NOT <constraint 1>
- Do NOT <constraint 2>
...

## Output Format

<Expected output structure, if applicable>
```

### Step 5: Generate Platform Outputs

Run the platform output generator to produce all 5 formats:

```powershell
& "<agent-forge-path>\scripts\build-platforms.ps1" -Agent <name>
```

Or if the script isn't available, manually create the platform files following `references/platform-formats.md`.

### Step 6: Validate

Run the validator to check structure, frontmatter, and description quality:

```powershell
& "<agent-forge-path>\scripts\validate-agent.ps1" -Path canonical\agents\<name>.md
```

Check for:
- Frontmatter has all required fields
- Description is 20-50 words with trigger phrases
- Tools list is minimal (not a kitchen sink)
- Constraints are specific and actionable
- No anti-patterns (see `references/anti-patterns.md`)

### Step 7: Test & Iterate

1. Install the agent to the target platform
2. Give it a representative task
3. Evaluate: Did it stay in role? Use the right tools? Respect constraints?
4. Refine the canonical file and regenerate platform outputs
5. Repeat until satisfied

### Step 8: Install

Place the agent at the correct platform location:

| Platform | Location |
|----------|----------|
| Copilot (personal) | `%APPDATA%\Code\User\prompts\<name>.agent.md` |
| Copilot (workspace) | `.github/agents/<name>.agent.md` |
| Claude Code (personal) | `~/.claude/agents/<name>.md` |
| Claude Code (workspace) | `.claude/agents/<name>.md` |
| Codex | Append to `AGENTS.md` |

---

## Quick Reference: Platform Formats

| Platform | File | Frontmatter | Tools Field | Model Field |
|----------|------|-------------|-------------|-------------|
| Copilot | `.agent.md` | YAML (`description`, `tools`, `model`) | Array of aliases | `model` or `model[]` |
| Claude Code | `.md` in `.claude/agents/` | None (conventions in body) | `## Tools` section | `## Model` section |
| Codex | `AGENTS.md` section | None | Described in prose | N/A |

For full format details, read `references/platform-formats.md`.

---

## Templates

Choose a template when you want a quick start. Each template is a complete canonical agent file with placeholder values.

| Template | Best For |
|----------|----------|
| `code-reviewer.md` | Agents that review PRs, audit code quality |
| `testing-specialist.md` | QA agents, test writers, coverage analyzers |
| `devops.md` | CI/CD, infrastructure, deployment agents |
| `domain-expert.md` | Specialized knowledge agents (.NET, React, etc.) |
| `coordinator.md` | Meta-agents that delegate to subagents |
| `read-only-researcher.md` | Agents that only read and analyze, never edit |

Read templates from `templates/<name>.md`.

---

## Subagent Orchestration

For agents that delegate to other agents, read `references/subagent-orchestration.md`. Key patterns:
- **Parallel research**: Spawn multiple read-only subagents for independent investigations
- **Chain pattern**: Sequential subagent calls, each building on previous results
- **Coordinator pattern**: A parent agent that routes tasks to specialists
- Subagents start with fresh context — include all needed info in the delegation prompt
- On Copilot, use `agents:` frontmatter field to list allowed subagents
- On Claude Code, use `Agent(name1, name2)` tool restriction

---

## Best Practices (Top 10)

1. **Single responsibility** — One focused role per agent. Don't build Swiss-army agents
2. **Minimal tools** — Only grant tools the role actually needs
3. **Keyword-rich descriptions** — Include trigger phrases for auto-delegation
4. **Imperative form** — "Review code for X" not "You should review code for X"
5. **Clear constraints** — Define what the agent must NOT do
6. **Show don't tell** — Use examples over lengthy explanations
7. **Test across platforms** — Behavior may differ between Copilot and Claude Code
8. **No secrets in agents** — Never embed API keys or credentials
9. **Match model to task** — Haiku for fast reads, Sonnet for balanced, Opus for complex reasoning
10. **Iterate with fresh eyes** — Use one session to create, another to review

For the full best-practices guide, read `references/best-practices.md`.
