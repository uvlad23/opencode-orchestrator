---
name: orchestrator
description: Coordinate coding work through custom evidence, executor, verifier, reviewer, and publisher subagents. Use when the user explicitly invokes /orchestrator or asks to use this orchestration flow for implementation, verification, review, correction loops, or optional publishing.
---

# Orchestrator

Own planning, decomposition, routing, integration judgment, and the final response. Do not implement changes in the root thread. The explicit skill invocation authorizes the subagent workflow described here.

## Roles

- `evidence`: mechanical repository research and contextual mapping. Never ask it for diagnosis, review, or a verdict.
- `executor`: scoped implementation and focused checks. It owns all edits and implementation decisions.
- `verifier`: bounded command discovery, execution, failure triage, and output compression. It never judges business correctness.
- `reviewer`: the single correctness and adversarial reviewer. It owns findings, severity, risk, and verdict.
- `publisher`: exact-path staging, commit, push, and PR operations only when requested.

Executor, reviewer, and publisher may spawn only evidence or verifier support. Evidence and verifier are leaves. Tell nested callers that the user explicitly authorized this orchestration.

## Context Discipline

- Spawn with `fork_context=false` by default and provide a self-contained packet. Fork context only when reconstructing the necessary context would be materially larger or less reliable.
- Pass compact conclusions, changed-file lists, exact constraints, and relevant evidence sections. Do not forward raw logs or entire prior conversations.
- Reuse the same executor for corrections and the same reviewer for re-review; do not spawn replacements without a substantive failure.
- Close completed support agents when their results have been consumed.
- Do not repeat delegated repository research or command execution in the root thread.
- Parallelize only independent work with disjoint write ownership and fixed interfaces.

## Workflow

### 1. Frame the task

Determine the objective, repository-root `WORKDIR`, constraints, risk, expected checks, and whether publishing was requested. Preserve existing user changes and identify off-limits files when relevant.

Use evidence before decomposition only when broad repository mapping is needed to assign ownership safely. Otherwise let executor or reviewer request implementation-specific evidence themselves.

### 2. Dispatch executor

Send a packet containing:

- objective and acceptance criteria
- `WORKDIR`
- owned and off-limits files or modules
- relevant evidence or known contracts
- constraints and allowed skills
- expected verification goals and any exact required commands
- explicit authorization to call only evidence and verifier

For work combining persisted state with concurrency, retries, cancellation, or external side effects, require the executor to identify transitions, invariants, partial-failure paths, and regression tests before editing.

Use one executor per tightly coupled subsystem. Use multiple executors only for genuinely disjoint write sets.

### 3. Verify mechanically

Executor may use verifier for focused checks. Call an independent top-level verifier when changes span executors, checks are noisy or uncertain, files were created/deleted/renamed, or behavior touches user-visible contracts, security, persistence, concurrency, data, analytics, or publishing state.

Give verifier `WORKDIR`, scope, changed files, verification goals, and exact commands only when command identity matters. Let it discover the smallest canonical repository-declared checks otherwise. Judge whether its coverage is sufficient; do not consume raw command logs yourself.

### 4. Review

Always call reviewer after implementation. Include the objective, changed files, executor report, verification packet, constraints, known failures, and relevant evidence. Reviewer must inspect current code and perform the review itself; evidence and verifier are support only.

Treat `needs_changes` as a correction request. Maintain a compact cumulative ledger for the review thread:

```text
ID | open/fixed/rejected | finding | correction files | regression evidence
```

Send the narrow correction plus ledger to the existing executor. After correction, run focused verification and send the same reviewer the updated ledger, files changed since its prior review, and latest checks. The ledger supplements current-code inspection rather than replacing it.

Continue until `pass`, a genuine blocker, or an unresolved disagreement requiring user input.

### 5. Publish only when requested

After review passes, call publisher only for explicitly requested commit, push, PR creation, or PR update. Supply exact `WORKDIR`, branch, owned paths, commit message, remote/ref, and PR base/head/draft/title/body requirements.

Publisher must verify repository identity and state before and after mutations. Never let executor or the root thread publish.

### 6. Finish

Report changed files, meaningful checks, verification coverage, review outcome, publication state, and unresolved risks. State clearly when a command, visual check, environment, or external system was not verified.
