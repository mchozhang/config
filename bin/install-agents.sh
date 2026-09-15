#!/usr/bin/env bash
# Installs/upgrades skills listed in ai-agents/config.yaml into ai-agents/skills/.
#
# Skills with `source: github` are vendored from their upstream repo (using the
# `skills` CLI, https://skills.sh) into ai-agents/skills/<name>/. Skills with
# `source: local` are authored directly in this repo and are only checked for
# existence.
#
# After installing, run ./bin/sync-agents.sh to refresh the global symlinks.

set -eu -o pipefail

basedir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$basedir/lib/utils.sh"

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
  esac
done

DRY_RUN="${DRY_RUN:-0}"

config_file="$basedir/ai-agents/config.yaml"

if ! command -v yq >/dev/null; then
  error "yq not found"
  exit 1
fi

if [ ! -f "$config_file" ]; then
  error "$config_file not found"
  exit 1
fi

log-separator "Installing agent skills"

skills_json="$(yq -o=json '.' "$config_file" | jq -c '.skills[] | select(.enabled != false)')"

# Verify locally authored skills are present; nothing to fetch for them.
while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  [ "$(jq -r '.source' <<<"$entry")" = "local" ] || continue

  name="$(jq -r '.name' <<<"$entry")"
  skill_md="$basedir/ai-agents/skills/$name/SKILL.md"
  if [ -f "$skill_md" ]; then
    log "$name is local, already present"
  else
    warn "$name is local but missing at $skill_md"
  fi
done <<<"$skills_json"

# Group github skills by their source repo, so each repo is fetched once even if
# it provides multiple skills (e.g. grill-me and grilling both live in mattpocock/skills).
declare -A repo_to_skills
declare -A skill_to_path

while IFS= read -r entry; do
  [ -z "$entry" ] && continue
  [ "$(jq -r '.source' <<<"$entry")" = "github" ] || continue

  name="$(jq -r '.name' <<<"$entry")"
  url="$(jq -r '.url' <<<"$entry")"
  path="$(jq -r '."skill-path"' <<<"$entry")"

  repo="${url#https://github.com/}"
  repo="${repo%.git}"

  repo_to_skills["$repo"]="${repo_to_skills[$repo]:-} $name"
  skill_to_path["$name"]="$path"
done <<<"$skills_json"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

for repo in "${!repo_to_skills[@]}"; do
  names=(${repo_to_skills[$repo]})
  work="$tmp_root/$(echo "$repo" | tr '/' '_')"
  mkdir -p "$work"

  log "fetching ${names[*]} from $repo"
  if ! (cd "$work" && npx --yes skills@latest add "$repo" --skill "${names[@]}" -a claude-code -y --copy) >/dev/null 2>&1; then
    warn "failed to fetch skills from $repo, skipping"
    continue
  fi

  for name in "${names[@]}"; do
    src="$work/.claude/skills/$name"
    dst="$basedir/ai-agents/skills/$name"

    if [ ! -d "$src" ]; then
      warn "$name not found upstream in $repo, skipping"
      continue
    fi

    # Re-attach source metadata that the CLI itself doesn't write, so the
    # repo/path stays discoverable for provenance and the next upgrade run.
    awk -v path="${skill_to_path[$name]}" -v repo="$repo" '
      { print }
      !done && $0 == "---" { print "metadata:"; print "    github-path: " path; print "    github-repo: https://github.com/" repo; done=1 }
    ' "$src/SKILL.md" > "$src/SKILL.md.tmp" && mv "$src/SKILL.md.tmp" "$src/SKILL.md"

    if diff -rq "$src" "$dst" >/dev/null 2>&1; then
      log "$name already up to date"
      continue
    fi

    if [ "$DRY_RUN" = "1" ]; then
      log "[dry-run] would install/update $name from $repo"
      diff -rq "$src" "$dst" || true
    else
      rm -rf "$dst"
      cp -R "$src" "$dst"
      log "installed/updated $name from $repo"
    fi
  done
done

log "Done. Review changes with 'git diff ai-agents/skills/', then run ./bin/sync-agents.sh to refresh symlinks."
