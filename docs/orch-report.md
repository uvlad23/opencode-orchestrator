# Orchestration Review Report

## Background

This report captures lessons learned from orchestration-driven development loops using evidence, executor, verifier, reviewer, and publisher subagents. The findings are based on real projects but have been generalized to remove private identifiers, paths, and infrastructure details.

## Key Lessons

### Evidence delegations

- **High-value evidence**: Initial repository discovery that surfaces core files, contracts, schema, and status boundaries saves substantial context for the orchestrator and executor.
- **Low-value evidence**: Repeated broad context gathering in later review rounds, when a compact cumulative ledger would have sufficed.
- **Missed opportunity**: Pre-implementation scouting of queue/state-machine code paths would have prevented many later defects.

### Verifier delegations

- **High-value verifier**: Focused test runs after each risky fix, full API test suites at integration milestones, and type-checking after schema changes.
- **Overhead**: Re-running the full test suite after every tiny backend-only change. Better policy: focused tests after narrow fixes; full suite only after a review pass or before publishing.

### Review/fix loops

Multiple review-fix loops surfaced defects that were genuinely new each round. Common root causes:

1. No explicit state-machine and failure-mode matrix before implementation.
2. Incomplete retry/persistence semantics in the executor packet.
3. No explicit "queue-before-cancel" or "DB-is-source-of-truth" ordering invariants.
4. Queue operations treated as atomic when they were not.

**Most defects were preventable** with a better executor packet that specified invariants upfront, rather than relying on reactive review to discover them.

### Publisher workspace identity

One incident showed that publisher status reporting (branch, HEAD, tree cleanliness) was not trustworthy without top-level confirmation. The push result was correct, but local cleanup reports were inconsistent. Recommendation: publishers should always report exact `pwd`, `git rev-parse --show-toplevel`, `git branch --show-current`, and `git status --porcelain=v1` in every report.

### Framework improvements

1. **State-machine section in executor packets**: When touching queues, jobs, retries, notifications, or persistence rollback, require a pre-code state machine, invariants, and failure matrix.
2. **Cumulative review ledger**: After every review, maintain a ledger of findings, status, fix commits, and regression tests. Pass this ledger (not full context) to subsequent reviewers.
3. **Publisher verification policy**: Mandatory workspace identity reporting before and after publishing, with top-level confirmation.
4. **Verification cadence**: Focused tests after narrow fixes, typecheck when interfaces change, full suite after a review pass or before publishing.
