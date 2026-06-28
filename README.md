# OpenCode Orchestrator

A disciplined multi-agent orchestration package for [OpenCode](https://github.com/opencode-ai/opencode) that routes coding work through 11 specialized subagents: contextual mapping, causal investigation, bounded implementation (3 tiers), mechanical verification (2 tiers), correctness review, adversarial risk review, and optional publishing.

## What it does

Instead of one model doing everything, the orchestrator decomposes a task and dispatches it to focused agents with distinct models and permissions:

### Full role matrix

| Role | Mode | Model | Permission | Primary job |
|------|------|-------|------------|-------------|
| **Orchestrator** | primary | openai/gpt-5.5 | read only, task allow | Plans, decomposes, routes, recovers, integrates, answers |
| **Evidence** | subagent | opencode-go/deepseek-v4-flash | read only | Mechanical repository mapping; facts, absences, limits |
| **Scout** | subagent | ollama-cloud/glm-5.2 | read only | Causal code-path investigation; state machine + failure matrix preflight |
| **Executor** | subagent | ollama-cloud/glm-5.2 | edit allow, bash ask, task allow (evidence, verifier) | Main complex implementation worker |
| **Executor-lite** | subagent | opencode-go/deepseek-v4-pro | edit allow, bash ask, task allow (evidence, verifier) | Simple bounded worker / recovery fallback |
| **Executor-patch** | subagent | opencode-go/deepseek-v4-flash | edit allow, bash deny, task deny | Exact mechanical patch worker; zero design judgment |
| **Verifier** | subagent | opencode-go/deepseek-v4-flash | read allow, bash ask | Default local mechanical verifier; exact commands |
| **Verifier-pro** | subagent | opencode-go/deepseek-v4-pro | read allow, bash ask | Escalated verification: SSH, remote, external, high-risk |
| **Reviewer** | subagent | openai/gpt-5.5 | read only, task allow (evidence, verifier) | Correctness reviewer; owns findings and verdict |
| **Risk-reviewer** | subagent | opencode-go/deepseek-v4-pro | read only, task allow (evidence, verifier) | Adversarial reviewer for security/data/concurrency/api/infra risk |
| **Publisher** | subagent | opencode-go/deepseek-v4-pro | read allow, bash ask | Git/GitHub publication; verify workspace identity |

Only the orchestrator can invoke agents. Every subagent is terminal — context isolation never creates a second orchestration layer.

## Routes

The orchestrator classifies every task into one of three routes:

### Normal route
For scoped, well-understood changes in a bounded subsystem:
```
Orchestrator -> Executor -> Verifier -> Reviewer
```

### Broad / risky route
For broad changes, unclear ownership, or risk-triggered work (persisted state, concurrency, security, API/schema, analytics, infrastructure, dependencies, user-visible behavior):
```
Orchestrator -> Evidence + Scout -> Executor(s) -> Verifier -> Reviewer + Risk-reviewer
```

### Recovery route
When a prior executor report is failed, inconsistent, or incomplete:
```
Orchestrator -> Verifier -> Evidence -> Executor-lite -> Verifier -> Reviewer
```

## Quick install

```bash
# Clone and install
git clone https://github.com/uvlad23/opencode-orchestrator.git
cd opencode-orchestrator
bash scripts/install.sh

# Restart OpenCode for changes to take effect
```

## Manual install

If you prefer to install by hand, copy these files:

| Source (in this repo) | Destination |
|------------------------|-------------|
| `skills/orchestrator/` | `~/.agents/skills/orchestrator/` |
| `agent/*.md` | `~/.config/opencode/agent/` |
| `command/orchestrator.md` | `~/.config/opencode/command/` |

Then restart OpenCode.

## Usage

### Via command

```
/orchestrator Add error handling to the payment processing module
```

### Via skill invocation

Type `/orchestrator` or mention `orchestrator` in your prompt.

### When it activates

The orchestrator skill activates when you explicitly invoke it or ask to use the orchestration flow. It does not activate implicitly for every task.

## Customization

- **Agent models**: Edit `agent/*.md` frontmatter to set `model:` per agent. The repo ships with the author's default routing and model assignments. If your provider availability differs, edit the `model:` fields in the agent frontmatter to match your available models before installing.
- **Skill behavior**: Modify `skills/orchestrator/SKILL.md` to adjust the workflow, routing rules, or trigger conditions.
- **OpenCode config**: Copy `opencode.json.example` to `opencode.json` in your project and customize paths. The example is minimal and uses only the supported `skills.paths` key — add other supported keys as needed.

## Correction loop

When the reviewer finds issues, the orchestrator maintains a cumulative review ledger:

```
ID | open/fixed/rejected | finding | correction files | regression evidence
```

A narrow correction is sent to the same executor (or executor-lite for simple fixes), followed by focused verification and re-review. The ledger supplements current-code inspection across correction cycles.

## Security

- The orchestrator cannot edit files or run shell commands. Only executors and publisher can write.
- The verifier runs only exact allowlisted commands; verifier-pro handles SSH and remote checks.
- No secrets, tokens, or private paths are included in this repository.
- Review agent definitions before installing. All files are plain text.

## Uninstall

```bash
bash scripts/uninstall.sh
```

This moves installed files into a timestamped backup directory under `~/.opencode-orchestrator-backups/`. Nothing is permanently deleted.

## Advanced documentation

- `docs/orch-report.md` — Lessons learned from orchestration-driven development loops across multiple projects.
- `docs/orchestration-map.html` — Reference diagram of the full orchestration flow.

## License

MIT. See [LICENSE](LICENSE).
