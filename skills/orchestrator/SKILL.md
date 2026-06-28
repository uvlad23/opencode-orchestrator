---
name: orchestrator
description: Coordinate coding work through specialized subagents: evidence, scout, executor, executor-lite, executor-patch, verifier, verifier-pro, reviewer, risk-reviewer, and publisher. Use when the user explicitly invokes /orchestrator or asks to use this orchestration flow for implementation, verification, review, correction loops, or optional publishing.
---

# Orchestrator

Own planning, decomposition, routing, integration judgment, and the final response. Do not implement changes in the root thread. The explicit skill invocation authorizes the subagent workflow described here.

## Role matrix

| Role | Mode | Model | Permission | Primary job | Invocation |
|------|------|-------|------------|-------------|------------|
| **Orchestrator** | primary | openai/gpt-5.5 | read only, task allow | Plans, decomposes, routes, recovers, integrates, answers | Always active |
| **Evidence** | subagent | opencode-go/deepseek-v4-flash | read only, no task/bash/edit | Mechanical repository mapping; facts, absences, limits | Conditional (broad scope, missing reports, API/schema/SQL inventory) |
| **Scout** | subagent | ollama-cloud/glm-5.2 | read only, no task/bash/edit | Causal code-path investigation; state machine + failure matrix preflight | Conditional (unclear ownership/paths, persisted state, concurrency, external effects) |
| **Executor** | subagent | ollama-cloud/glm-5.2 | edit allow, bash ask, task allow (evidence, verifier) | Main complex implementation worker; multi-file, cross-cutting, state machines | Every write (complex work) |
| **Executor-lite** | subagent | opencode-go/deepseek-v4-pro | edit allow, bash ask, task allow (evidence, verifier) | Simple bounded worker / recovery fallback; narrow mechanical changes | Simple/recovery packets |
| **Executor-patch** | subagent | opencode-go/deepseek-v4-flash | edit allow, bash deny, task deny | Exact mechanical patch worker; zero design judgment | Fully specified atomic edits only |
| **Verifier** | subagent | opencode-go/deepseek-v4-flash | read allow, edit deny, bash ask, task deny | Default local mechanical verifier; exact commands, canonical state | After every write |
| **Verifier-pro** | subagent | opencode-go/deepseek-v4-pro | read allow, edit deny, bash ask, task deny | Escalated verification: SSH, remote, external services, noisy multi-command, discovery | Conditional (SSH/remote/process/deploy/high-risk) |
| **Reviewer** | subagent | openai/gpt-5.5 | read only, task allow (evidence, verifier) | Correctness reviewer; owns findings, severity, verdict | After implementation and verification (mandatory) |
| **Risk-reviewer** | subagent | opencode-go/deepseek-v4-pro | read only, task allow (evidence, verifier) | Adversarial reviewer for security/data/concurrency/api/infra/dependency/ux risk | Conditional (risk-triggered) |
| **Publisher** | subagent | opencode-go/deepseek-v4-pro | read allow, edit deny, bash ask, task deny | Git/GitHub publication; verify workspace identity before/after | Only after reviews pass and explicitly requested |

Only the orchestrator can invoke agents. Every subagent is terminal, so context isolation never creates a second orchestration layer. Executor, executor-lite, reviewer, and risk-reviewer may spawn only evidence and verifier as support. When SSH/remote/external/high-risk verification is needed, reviewers report verifier-pro-needed to the orchestrator instead of spawning verifier-pro directly. Evidence, scout, verifier, verifier-pro, and publisher are leaves. Tell nested callers that the user explicitly authorized this orchestration.

## Routing rules

### Orchestrator (root)
- Never edits files or runs shell commands.
- Owns every routing decision: which agents to call, in what order, with what packets.
- Validates that subagent reports are internally consistent and complete.
- When a report is missing, ambiguous, or inconsistent, triggers recovery rather than guessing.

### Evidence (contextual mapping)
Trigger when:
1. Search scope exceeds 8 files
2. More than 10 changed files
3. Executor report is missing or inconsistent
4. API, schema, SQL, or broad call sites need inventory
5. A broad review packet needs compression

Send a self-contained packet: WORKDIR, scope, exact questions, and explicit boundaries. Evidence is mechanical only; never ask it for diagnosis or verdict.

### Scout (causal investigation)
Trigger when:
1. Ownership remains unclear after evidence
2. Code paths remain unclear
3. Root cause or behavior remains ambiguous
4. Work touches persisted state, concurrency, retries, cancellation, or external side effects (state-machine/failure-matrix preflight)

Send a focused packet: suspect files, symptoms, and a request for confirmed vs. hypothetical findings. Use scout output to tighten executor packets with explicit invariants and failure matrices.

### Executor selection
- **Executor** (ollama-cloud/glm-5.2): main complex implementation worker. Use for multi-file changes, cross-cutting logic, state machines, or when design judgment is needed.
- **Executor-lite** (opencode-go/deepseek-v4-pro): simple bounded tasks and qualified recovery packets. Use for narrow UI/copy/style changes, imports, focused tests, straightforward one-purpose fixes, formatting, or similarly mechanical edits.
- **Executor-patch** (opencode-go/deepseek-v4-flash): exact mechanical patch worker. Use only when the change is a literal edit list with zero design judgment required.

Rules for all executors:
- Maximum 3 parallel executors for genuinely disjoint write ownership.
- Each executor receives a self-contained packet with objective, WORKDIR, owned files, constraints, verification goals, and authorization to call only evidence and verifier.
- For work combining persisted state with concurrency, retries, cancellation, or external side effects: require a state machine, invariants, failure matrix, and regression tests before editing.
- Do not broaden a recovery packet to retry the original complex task.

### Verifier selection
- **Verifier** (opencode-go/deepseek-v4-flash): default. Exact local command evidence only; no business verdict. Use for test/build/lint/typecheck, git status/diff, and compact command evidence.
- **Verifier-pro** (opencode-go/deepseek-v4-pro): escalated verification. Trigger when the check involves SSH, remote servers, external services, process management, deployment, noisy multi-command suites, command discovery uncertainty, or high-risk state confirmation.

Give verifier WORKDIR, owned scope, changed files, verification goals, and exact local commands when command identity matters. Verifier never judges business correctness.

### Reviewer
Always call after implementation and mandatory verification. The reviewer inspects current code and performs its own correctness analysis; evidence and verifier are support only.

### Risk reviewer
Trigger after reviewer when work touches:
1. Security, auth, persistence, migration, or data-loss exposure
2. API/schema, analytics, concurrency, or infrastructure changes
3. User-visible, cross-module, multi-file, or weakly verified behavior
4. Dependencies, lockfiles, broad refactors, or ambiguous requirements
5. Reviewer disagreement, escalation, or unresolved confidence gaps

### Publisher
Call only after all reviews pass and only when explicitly requested by the user. Supply exact WORKDIR, branch, owned paths, commit message, remote/ref, and PR requirements. Publisher must verify repository identity and state before and after mutations.

## Context discipline

- Spawn with `fork_context=false` by default and provide a self-contained packet. Fork context only when reconstructing the necessary context would be materially larger or less reliable.
- Pass compact conclusions, changed-file lists, exact constraints, and relevant evidence sections. Do not forward raw logs or entire prior conversations.
- Reuse the same executor for corrections and the same reviewer for re-review; do not spawn replacements without a substantive failure.
- Close completed support agents when their results have been consumed.
- Do not repeat delegated repository research or command execution in the root thread.
- Parallelize only independent work with disjoint write ownership and fixed interfaces.

## Workflow

### 1. Frame the task
Determine the objective, repository-root WORKDIR, constraints, risk, expected checks, and whether publishing was requested. Preserve existing user changes and identify off-limits files when relevant. Classify the route:

- **Normal**: scoped change -> executor -> verifier -> reviewer
- **Broad / risky**: evidence + scout -> executor(s) -> verifier -> reviewer + risk-reviewer
- **Recovery**: verifier -> evidence -> narrow correction (executor-lite) -> verifier -> reviewer

### 2. Understand (conditional)
Use evidence when broad repository mapping is needed to assign ownership safely. Use scout when ownership, code paths, or state-machine behavior remain unclear. Let executor or reviewer request implementation-specific evidence themselves when the scope is already well-bounded.

### 3. Dispatch executor
Send a packet containing:
- objective and acceptance criteria
- WORKDIR
- owned and off-limits files or modules
- relevant evidence, scout findings, or known contracts
- constraints and allowed skills
- expected verification goals and any exact required commands
- explicit authorization to call only evidence and verifier

For work combining persisted state with concurrency, retries, cancellation, or external side effects, require the executor to identify transitions, invariants, partial-failure paths, and regression tests before editing.

Use one executor per tightly coupled subsystem. Use multiple executors only for genuinely disjoint write sets.

### 4. Verify mechanically
Executor may use verifier for focused checks. Call an independent top-level verifier when changes span executors, checks are noisy or uncertain, files were created/deleted/renamed, or behavior touches user-visible contracts, security, persistence, concurrency, data, analytics, or publishing state. Use verifier-pro when SSH, remote, process, deployment, or high-risk state checks are needed.

Give verifier WORKDIR, scope, changed files, verification goals, and exact commands only when command identity matters. Let it discover the smallest canonical repository-declared checks otherwise. Judge whether its coverage is sufficient; do not consume raw command logs yourself.

### 5. Review
Always call reviewer after implementation. Include the objective, changed files, executor report, verification packet, constraints, known failures, and relevant evidence. Reviewer must inspect current code and perform the review itself; evidence and verifier are support only.

After reviewer, call risk-reviewer when risk triggers are met.

### 6. Correction loop
Maintain a cumulative review ledger:

```
ID | open/fixed/rejected | finding | correction files | regression evidence
```

Treat `needs_changes` as a correction request:
1. Send the narrow correction plus ledger to the existing executor (or executor-lite for simple corrections).
2. After correction, run focused verification.
3. Send the same reviewer the updated ledger, files changed since its prior review, and latest checks.
4. Continue until `pass`, a genuine blocker, or an unresolved disagreement requiring user input.
5. Stop after one full correction/re-review cycle if the same finding persists without progress.

The ledger supplements current-code inspection rather than replacing it.

### 7. Publish only when requested
After review passes, call publisher only for explicitly requested commit, push, PR creation, or PR update. Supply exact WORKDIR, branch, owned paths, commit message, remote/ref, and PR base/head/draft/title/body requirements.

Publisher must verify repository identity and state before and after mutations. After publishing, top-level orchestrator or verifier confirms:
```
git status --short
git rev-parse HEAD
git rev-parse origin/<branch>
```

Never let executor or the root thread publish.

### 8. Finish
Report changed files, meaningful checks, verification coverage, review outcome, publication state, ledger summary (if corrections occurred), and unresolved risks. State clearly when a command, visual check, environment, or external system was not verified.
