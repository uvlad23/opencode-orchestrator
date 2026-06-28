# OpenCode Orchestrator

A disciplined multi-agent orchestration flow for [OpenCode](https://github.com/opencode-ai/opencode) that routes coding work through specialized subagents: evidence gathering, bounded execution, mechanical verification, correctness review, and optional publishing.

## What it does

Instead of one model doing everything, the orchestrator decomposes a task and dispatches it to focused agents:

| Agent | Role | Access |
|-------|------|--------|
| **Evidence** | Mechanical repository research and contextual mapping | Read only |
| **Executor** | Scoped implementation with write authority | Read, write, shell |
| **Verifier** | Exact command execution and output capture | Read, shell (allowlisted) |
| **Reviewer** | Correctness review of current code | Read only |
| **Publisher** | Git staging, commit, push, PR creation | Read, shell |

The orchestrator (your primary model) owns planning, decomposition, routing, integration judgment, and the final response. It never implements changes directly.

## Quick install

```bash
# Clone and install
git clone https://github.com/Ziberoncheg/opencode-orchestrator.git
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

## Restart OpenCode

After installing, restart OpenCode so it discovers the new skill, agent definitions, and command. The install script prints a reminder.

## Customization

- **Agent models**: Edit `agent/*.md` frontmatter to set `model:` per agent. The repo ships without model assignments so you can configure your own.
- **Skill behavior**: Modify `skills/orchestrator/SKILL.md` to adjust the workflow.
- **OpenCode config**: Copy `opencode.json.example` to `opencode.json` in your project and customize paths. The example is minimal and uses only the supported `skills.paths` key — add other supported keys as needed.

## Advanced documentation

- `docs/orch-report.md` — Lessons learned from orchestration-driven development loops across multiple projects.
- `docs/orchestration-map.html` — Reference diagram of the full orchestration flow, including optional roles beyond the minimal package install.

## Security

- The orchestrator cannot edit files or run shell commands. Only the executor and publisher can write.
- The verifier runs only exact allowlisted commands.
- No secrets, tokens, or private paths are included in this repository.
- Review agent definitions before installing. All files are plain text.

## Uninstall

```bash
bash scripts/uninstall.sh
```

This moves installed files into a timestamped backup directory under `~/.opencode-orchestrator-backups/`. Nothing is permanently deleted.

## License

MIT. See [LICENSE](LICENSE).
