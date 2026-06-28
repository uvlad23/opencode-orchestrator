#!/usr/bin/env bash
set -euo pipefail

# OpenCode Orchestrator - Install Script
# Copies skill, agent, and command files into OpenCode config directories.
# Backs up existing files with a timestamp suffix before replacing.

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_SRC="${REPO_DIR}/skills/orchestrator"
AGENT_SRC="${REPO_DIR}/agent"
COMMAND_SRC="${REPO_DIR}/command/orchestrator.md"

SKILL_DEST="${HOME}/.agents/skills/orchestrator"
AGENT_DEST="${HOME}/.config/opencode/agent"
COMMAND_DEST="${HOME}/.config/opencode/command/orchestrator.md"

echo "==> OpenCode Orchestrator Install"
echo "    Source: ${REPO_DIR}"
echo "    Timestamp: ${TIMESTAMP}"
echo ""

# --- Install skill ---
echo "--- Skill: ${SKILL_DEST}"
if [ -e "${SKILL_DEST}" ]; then
  BACKUP="${SKILL_DEST}.backup.${TIMESTAMP}"
  echo "    Backing up existing to ${BACKUP}"
  mv "${SKILL_DEST}" "${BACKUP}"
fi
mkdir -p "$(dirname "${SKILL_DEST}")"
cp -R "${SKILL_SRC}" "${SKILL_DEST}"
echo "    Installed"

# --- Install agents ---
echo "--- Agents: ${AGENT_DEST}"
mkdir -p "${AGENT_DEST}"
for agent_file in "${AGENT_SRC}"/*.md; do
  agent_name=$(basename "${agent_file}")
  dest_file="${AGENT_DEST}/${agent_name}"
  if [ -e "${dest_file}" ]; then
    BACKUP="${dest_file}.backup.${TIMESTAMP}"
    echo "    Backing up ${agent_name} to ${BACKUP}"
    mv "${dest_file}" "${BACKUP}"
  fi
  cp "${agent_file}" "${dest_file}"
  echo "    Installed ${agent_name}"
done

# --- Install command ---
echo "--- Command: ${COMMAND_DEST}"
if [ -e "${COMMAND_DEST}" ]; then
  BACKUP="${COMMAND_DEST}.backup.${TIMESTAMP}"
  echo "    Backing up existing to ${BACKUP}"
  mv "${COMMAND_DEST}" "${BACKUP}"
fi
mkdir -p "$(dirname "${COMMAND_DEST}")"
cp "${COMMAND_SRC}" "${COMMAND_DEST}"
echo "    Installed"

echo ""
echo "==> Install complete"
echo ""
echo "    Restart OpenCode for changes to take effect."
echo "    Usage: /orchestrator <your task>"
