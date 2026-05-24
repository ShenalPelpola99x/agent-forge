# Agent Anti-Patterns

Common mistakes when creating agents and how to fix them.

---

## 1. Swiss-Army Agent
**Problem**: Agent has too many tools, too many responsibilities, tries to do everything.
**Symptom**: Agent gives mediocre results on all tasks, never excels at any.
**Fix**: Split into focused specialists. One agent = one role.

## 2. Vague Description
**Problem**: Description like "A helpful agent" or "Assists with coding tasks."
**Symptom**: Agent never gets auto-delegated to because the platform can't match requests.
**Fix**: Include specific trigger phrases, domain nouns, and action verbs. "Playwright E2E testing specialist. Use when writing browser tests, debugging test failures, or analyzing test coverage."

## 3. Role Confusion
**Problem**: Description says one thing, body instructions say another.
**Symptom**: Agent takes on tasks it shouldn't, or refuses tasks it should handle.
**Fix**: Align description and body. The description is a contract — the body fulfills it.

## 4. Kitchen-Sink Tools
**Problem**: Giving every tool to every agent "just in case."
**Symptom**: Read-only researcher accidentally edits files. Review agent runs deploys.
**Fix**: Start with zero tools, add only what the role requires.

## 5. Missing Constraints
**Problem**: No boundaries on what the agent should NOT do.
**Symptom**: Agent modifies files it shouldn't, runs destructive commands, goes off-scope.
**Fix**: Add explicit constraints: "Do NOT modify production config", "Do NOT run delete commands."

## 6. Over-Specified Instructions
**Problem**: Including information the model already knows (how HTTP works, what JavaScript is).
**Symptom**: Bloated agent file, wasted context window, slower performance.
**Fix**: Only include information specific to your codebase, conventions, or unique requirements.

## 7. Inconsistent Terminology
**Problem**: Mixing terms for the same concept — "field"/"box"/"input"/"element".
**Symptom**: Agent gets confused, inconsistent behavior across conversations.
**Fix**: Pick one term per concept and use it consistently throughout.

## 8. Time-Sensitive Instructions
**Problem**: "If before August 2025, use the old API. Otherwise, use the new API."
**Symptom**: Agent can't reliably determine current date, gives stale guidance.
**Fix**: Remove conditional logic based on time. Just state the current correct approach.

## 9. Too Many Options
**Problem**: "You can either do A, B, C, or D. Each has tradeoffs..."
**Symptom**: Agent picks randomly or gets stuck deciding.
**Fix**: Give a clear default with escape hatches: "Use approach A. If the user specifically asks for B, do B instead."

## 10. Deeply Nested References
**Problem**: Agent references file A, which references file B, which references file C.
**Symptom**: Context gets lost along the chain, model forgets original instruction.
**Fix**: Keep reference depth to 1 level. Agent → reference file. No reference → reference chains.

## 11. Circular Handoffs
**Problem**: Agent A → Agent B → Agent A without progress criteria.
**Symptom**: Infinite loop, no work gets done, context grows until failure.
**Fix**: Add progress criteria: "Only delegate if you cannot handle this yourself."

## 12. No Output Format
**Problem**: Agent has no guidance on what its output should look like.
**Symptom**: Wildly inconsistent output format across invocations.
**Fix**: Define an output format section: "Return a markdown table with columns: File, Issue, Severity, Suggestion."
