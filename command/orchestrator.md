---
description: Route implementation tasks through specialized subagents: evidence, executor, verifier, reviewer, and publisher.
argument:
  name: task
  description: The implementation task to orchestrate
  required: true
---

Use the orchestrator skill to plan, decompose, and route the following task through specialized subagents:

**Task:** $ARGUMENTS

Follow the orchestrator workflow:
1. Frame the task and determine WORKDIR, constraints, and risk
2. Dispatch executor with a self-contained implementation packet
3. Verify mechanically after implementation
4. Review for correctness
5. Publish only if explicitly requested
6. Report changed files, verification coverage, review outcome, and unresolved risks

Do not implement changes directly. Delegate all writes to the executor. Use evidence for broad repository research before assigning ownership when needed.
