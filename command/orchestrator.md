---
description: Route implementation tasks through specialized subagents: evidence, scout, executor, executor-lite, executor-patch, verifier, verifier-pro, reviewer, risk-reviewer, and publisher.
agent: orchestrator
argument:
  name: task
  description: The implementation task to orchestrate
  required: true
---

Use the orchestrator skill to plan, decompose, and route the following task through specialized subagents:

**Task:** $ARGUMENTS

Follow the orchestrator workflow. Do not implement changes directly in the root thread.

## Route classification

Determine the route based on the task:

### Normal route
For scoped, well-understood changes in a bounded subsystem:
1. Frame the task (WORKDIR, constraints, risk)
2. Dispatch executor with a self-contained implementation packet
3. Verify mechanically with verifier
4. Review for correctness with reviewer
5. Publish only if explicitly requested

### Broad / risky route
For broad changes, unclear ownership, or risk-triggered work (persisted state, concurrency, security, API/schema, analytics, infrastructure, dependencies, user-visible behavior):
1. Frame the task
2. Dispatch evidence for broad repository mapping
3. Dispatch scout if ownership, code paths, or state-machine behavior remain unclear
4. Dispatch executor(s) (max 3, disjoint ownership) with scout/evidence-informed packets
5. Verify mechanically with verifier (or verifier-pro for SSH/remote/high-risk checks)
6. Review for correctness with reviewer
7. Dispatch risk-reviewer for adversarial review
8. Publish only if explicitly requested

### Recovery route
When a prior executor report is failed, inconsistent, or incomplete:
1. Run verifier to establish canonical repository state
2. Dispatch evidence to map current state if needed
3. Send a narrow correction packet to executor-lite (or executor for complex corrections)
4. Re-verify with verifier
5. Re-review with reviewer (targeting only changed files)
6. Update the cumulative review ledger

## Forbidden actions
- Do not implement changes directly
- Do not delegate planning, routing, or integration judgment
- Do not run shell commands
- Do not edit files
- Do not publish (delegate to publisher)
- Do not skip mandatory verification or review

## Output
Report: changed files, meaningful checks and results, verification coverage, review outcome, publication state, ledger summary (if corrections occurred), and unresolved risks.
