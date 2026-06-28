#!/usr/bin/env bash
set -euo pipefail

# OpenCode Orchestrator - Uninstall Script
# Moves installed skill, agent, and command files into a timestamped backup directory.
# Nothing is permanently deleted.

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${HOME}/.opencode-orchestrator-backups/uninstall-${TIMESTAMP}"

SKILL_PATH="${HOME}/.agents/skills/orchestrator"
AGENT_DIR="${HOME}/.config/opencode/agent"
COMMAND_FILE="${HOME}/.config/opencode/command/orchestrator.md"

echo "==> OpenCode Orchestrator Uninstall"
echo "    Timestamp: ${TIMESTAMP}"
echo "    Backup dir: ${BACKUP_DIR}"
echo ""

mkdir -p "${BACKUP_DIR}"

moved_any=false

# --- Uninstall skill ---
if [ -e "${SKILL_PATH}" ]; then
  echo "--- Moving skill: ${SKILL_PATH} -> ${BACKUP_DIR}/skill/"
  mkdir -p "${BACKUP_DIR}/skill"
  mv "${SKILL_PATH}" "${BACKUP_DIR}/skill/"
  moved_any=true
else
  echo "--- Skill not found: ${SKILL_PATH}"
fi

# --- Uninstall agents (all orchestrator agents) ---
AGENT_FILES=(
  "orchestrator.md"
  "evidence.md"
  "scout.md"
  "executor.md"
  "executor-lite.md"
  "executor-patch.md"
  "verifier.md"
  "verifier-pro.md"
  "reviewer.md"
  "risk-reviewer.md"
  "publisher.md"
)

for agent_name in "${AGENT_FILES[@]}"; do
  agent_file="${AGENT_DIR}/${agent_name}"
  if [ -e "${agent_file}" ]; then
    echo "--- Moving agent: ${agent_file} -> ${BACKUP_DIR}/agent/"
    mkdir -p "${BACKUP_DIR}/agent"
    mv "${agent_file}" "${BACKUP_DIR}/agent/"
    moved_any=true
  else
    echo "--- Agent not found: ${agent_file}"
  fi
done

# --- Uninstall command ---
if [ -e "${COMMAND_FILE}" ]; then
  echo "--- Moving command: ${COMMAND_FILE} -> ${BACKUP_DIR}/command/"
  mkdir -p "${BACKUP_DIR}/command"
  mv "${COMMAND_FILE}" "${BACKUP_DIR}/command/"
  moved_any=true
else
  echo "--- Command not found: ${COMMAND_FILE}"
fi

echo ""

if [ "${moved_any}" = true ]; then
  echo "==> Uninstall complete. Files moved to ${BACKUP_DIR}"
else
  echo "==> Nothing to uninstall. No orchestrator files were found."
fi

echo ""
echo "    Restart OpenCode for changes to take effect."
