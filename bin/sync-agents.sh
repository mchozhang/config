#!/usr/bin/env bash
# Symlinks ai-agents/ content (skills, agents, and the global instructions doc) into
# each tool's real global config location, so GitHub Copilot, OpenCode, Claude Code,
# and Kiro CLI all share the same source of truth.
#
# Run ./bin/install-agents.sh first to fetch/update github-sourced skills.

set -eu -o pipefail

basedir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$basedir/lib/utils.sh"
source "$basedir/lib/install.sh"

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
  esac
done

DRY_RUN="${DRY_RUN:-0}"
export DRY_RUN

config_file="$basedir/ai-agents/config.yaml"
agents_dir="$basedir/ai-agents/agents"
skills_dir="$basedir/ai-agents/skills"
xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

# ── Global instructions (AGENTS.md) ─────────────────────────────────────────
# One canonical file, symlinked verbatim into every tool's real instructions path.
log-separator "Syncing global agent instructions"

for dst in \
  "$HOME/.copilot/copilot-instructions.md" \
  "$xdg_config_home/opencode/AGENTS.md" \
  "$HOME/.claude/CLAUDE.md" \
  "$HOME/.kiro/steering/AGENTS.md"
do
  link "$basedir/ai-agents/AGENTS.md" "$dst"
done

# ── Global agents ────────────────────────────────────────────────────────────
# Each agent file carries one canonical frontmatter (union of what every tool needs);
# only the destination filename convention differs per tool.
#
# Kiro CLI is intentionally excluded here: its global agents are JSON files with a
# `prompt` string field (see `kiro-cli agent create`), not markdown+frontmatter, so a
# plain symlink doesn't work. Kiro still gets skills and instructions above; agent
# support would need a real markdown→JSON generator, which is out of scope for now.
log-separator "Syncing global agents"

for agent_src in "$agents_dir"/*.md; do
  [ -f "$agent_src" ] || continue
  name="$(basename "$agent_src" .md)"

  link "$agent_src" "$HOME/.copilot/agents/$name.agent.md"
  link "$agent_src" "$xdg_config_home/opencode/agents/$name.md"
  link "$agent_src" "$HOME/.claude/agents/$name.md"
done

# ── Skills ───────────────────────────────────────────────────────────────────
log-separator "Syncing global agent skills"

tool_skill_paths=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.kiro/skills"
)

if command -v yq >/dev/null 2>&1 && [ -f "$config_file" ]; then
  enabled_skills="$(yq -o=json '.' "$config_file" | jq -r '.skills[] | select(.enabled != false) | .name')"
else
  warn "cannot read $config_file, syncing all skills present under ai-agents/skills/"
  enabled_skills=""
  for d in "$skills_dir"/*/; do
    [ -f "$d/SKILL.md" ] && enabled_skills="$enabled_skills$(basename "$d")"$'\n'
  done
fi

is-enabled() {
  grep -qx "$1" <<<"$enabled_skills"
}

for tool_path in "${tool_skill_paths[@]}"; do
  for skill_dir in "$skills_dir"/*; do
    [ -f "$skill_dir/SKILL.md" ] || continue

    skill_name="$(basename "$skill_dir")"
    dst_skill_dir="$tool_path/$skill_name"

    if ! is-enabled "$skill_name"; then
      # Disabled in config.yaml — remove a stale symlink we own, but never touch a
      # foreign file/dir or a symlink pointing elsewhere.
      if [ -L "$dst_skill_dir" ] && [ "$(readlink "$dst_skill_dir")" = "$skill_dir" ]; then
        if [ "$DRY_RUN" = "1" ]; then
          log "[dry-run] would remove disabled skill link: $dst_skill_dir"
        else
          rm -f "$dst_skill_dir"
          log "removed disabled skill link: $dst_skill_dir"
        fi
      fi
      continue
    fi

    if [ -L "$dst_skill_dir" ] && [ "$(readlink "$dst_skill_dir")" = "$skill_dir" ]; then
      log "already linked: $skill_dir → $dst_skill_dir"
    elif [ -e "$dst_skill_dir" ] || [ -L "$dst_skill_dir" ]; then
      # dst_skill_dir is a real file/dir or a symlink pointing elsewhere: replace it
      if [ "$DRY_RUN" = "1" ]; then
        log "[dry-run] would replace existing link: $dst_skill_dir → $skill_dir"
      else
        rm -rf "$dst_skill_dir"
        link "$skill_dir" "$dst_skill_dir"
      fi
    else
      link "$skill_dir" "$dst_skill_dir"
    fi
  done
done

log "Global agent config synced."
