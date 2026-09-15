# config

This repo manages local tool configurations. When suggesting changes or generating code, follow these conventions.

## Constraints

- In agent mode, do not run extra commands to perform tasks that I didn't ask for, such as syntax check or code test.
- If commands are necessary to run to get information, do it conservatively and explain why it's necessary.

## Coding Style

### Code Writing Standards

- Follow established code-writing standards for your language (spacing, comments, naming).
- Consider internal coding rules for folder and function naming.

### Comment Usage

- Use comments sparingly and make them meaningful.
- Avoid commenting on obvious things; use comments to explain "why" or unusual behavior.

## Folder Structure

### config file

config files are `config.yaml` and `config.*.yaml`, which define tools to install and their config. 
Each config file has below properties:
- `enabled`: true by default, whether to enable this config file (true/false), if disabled, all tools defined in this config file will be ignored even if they are enabled individually.
- `priority`: 100 by default, lower number means higher priority. If multiple config files define the same tool, the one with higher priority will be used.
- `tools`: an array of tools' config


### tools
`tools` defines an array of tools' config, each tool has below properties:
- `name`: (mandatory) tool name, must match the folder name under `xdg/` if it has one. For example, `fzf` or `ghostty`.
- `enabled`: `true` by default, whether to install/sync this tool's config (true/false).
- `install`: (optional) key-value pairs of OS and the respective command to install the tool. For example:
  ```yaml
   # for macos
   install:
     macos: |
       brew-install fzf
    # for any os
  install:
    default: |
      git-install https://github.com/romkatv/powerlevel10k.git
  ```
- `install-priority`: (optional) default 100. lower number are installed first. This is useful when some tools depend on others being installed first.
- `bootstrap`: (optional) a list of bootstrap steps, each step has `priority`(by default 100) and key-value pairs of OS(`default` for all OSs) and the respective command to run at shell boostrap(e.g. `.zshrc`, `.bashrc`). For example, for `fzf`:
  ```yaml
  bootstrap:
    - priority: 100
      default: |
        source <(fzf --zsh)
        source "$HOME/.config/fzf/.fzf.zsh"    
  ```

### XDG Config (`xdg/`)
- Each tool has a subfolder under `xdg/`
- Each file is symlinked individually at the leaf level into `~/.config/<tool>/`.

### Home Files (`home/`)
- The same folder structure will be maintained under `home/` as the target structure under `~`.
- Each file is symlinked individually at the leaf level into the matching path under `~`.

### ai-agents (`ai-agents/`)
- Source of truth for global AI agent tooling config, shared across GitHub Copilot, OpenCode, Claude Code, and Kiro CLI.
- `ai-agents/config.yaml` lists skills to vendor. Each entry has:
  - `name`: (mandatory) skill name; must match the folder name under `ai-agents/skills/`.
  - `enabled`: `true` by default, whether to fetch/sync this skill.
  - `source`: `local` (authored directly in this repo) or `github` (vendored from an upstream repo).
  - `url`: (github only) the upstream repo to fetch from.
  - `skill-path`: for `source: local`, the path to the skill's `SKILL.md` in this repo; for `source: github`, the path to the skill within the upstream repo (used to locate it, and re-stamped into `SKILL.md` frontmatter as provenance metadata after fetching).
- `ai-agents/AGENTS.md` is the single canonical global instructions doc (equivalent to `AGENTS.md`/`CLAUDE.md`/`copilot-instructions.md`), symlinked verbatim into every tool's real instructions path.
- `ai-agents/agents/*.md` are canonical global subagents. Each file carries one frontmatter block (the union of fields every target tool needs); only the destination filename convention differs per tool.
- `ai-agents/skills/<name>/` holds the vendored or locally authored skill content.
- Unlike `xdg/`/`home/`, which mirror a single source into a single destination, `ai-agents/` content fans out from one source to multiple real per-tool locations (not into `xdg/`/`home/`), so it uses its own scripts:
  - `bin/install-agents.sh` fetches/upgrades `source: github` skills into `ai-agents/skills/`.
  - `bin/sync-agents.sh` symlinks `ai-agents/AGENTS.md`, `ai-agents/agents/*.md`, and `ai-agents/skills/*/` into:
    - `~/.copilot/copilot-instructions.md`, `~/.copilot/agents/<name>.agent.md`
    - `~/.config/opencode/AGENTS.md`, `~/.config/opencode/agents/<name>.md`
    - `~/.claude/CLAUDE.md`, `~/.claude/agents/<name>.md`
    - `~/.agents/skills/<name>` (Copilot/OpenCode), `~/.claude/skills/<name>`, `~/.kiro/skills/<name>`
  - Skills disabled in `config.yaml` have their symlinks removed on next sync (only symlinks owned by this repo are touched; foreign files/dirs are never removed).

## Scripts (`bin/`, `lib/`)

- `bin/` contains executable scripts
- `lib/` contains helper function scripts sourced by scripts in `bin/` or other `lib/` scripts; not executed directly
- Scripts that make changes must support a `--dry-run` mode or respect a `DRY_RUN`(0 or 1) environment variable to preview changes without applying them
- Scripts must be able to run in both zsh and bash environments
- Scripts should follow shellcheck best practices and be POSIX compliant where possible
- Scripts must be idempotent and print their actions for auditability
- use utils function for logging, error handling

### `bin/build-json-config.sh`

- generate config.lock.json from `config.*.yaml` and `config.yaml`, combine tools in those yaml into a single json array and convert yaml format to json. If there are duplicates, the last one wins.
Expected output format example:
```json
{
  "tools": [
    {
      "name": "fzf",
      ...
    },
    {
      "name": "ghostty",
      ...
    }
  ]
}
```
- output json to stdout in dry-run mode, and to `config.lock.json` file in normal run.

### `bin/sync-xdg.sh`
- Syncs all files from `xdg/` to their respective locations in `~/.config/`
- Creates necessary directories if they don't exist
- Create or update all symlinks for xdg configurations
- Execute:
  - Dry run (preview changes without applying): `./bin/sync-xdg.sh --dry-run`
  - Apply changes: `./bin/sync-xdg.sh`

### `bin/sync-home.sh`
- Syncs all files from `home/` to their respective locations in `~`
- Creates necessary directories if they don't exist
- Create or update all symlinks for home configurations
- Normal run: `bin/sync-home.sh`
- Execute:
  - Dry run (preview changes without applying): `./bin/sync-home.sh --dry-run`
  - Apply changes: `./bin/sync-home.sh`

### `bin/install-agents.sh`
- Reads `ai-agents/config.yaml` and fetches/upgrades every enabled `source: github` skill into `ai-agents/skills/<name>/`, using the `skills` CLI (https://skills.sh) via `npx`.
- Groups skills by upstream repo `url` so a repo shared by multiple skills (e.g. `grill-me` and `grilling`) is fetched only once.
- Re-stamps `metadata.github-repo`/`metadata.github-path` into each skill's `SKILL.md` frontmatter after fetching, so provenance stays discoverable for the next upgrade.
- `source: local` skills are only checked for existence (nothing to fetch).
- Must support the repository's standard dry-run behavior:
  - Dry run (preview changes without applying): `./bin/install-agents.sh --dry-run`
  - Apply changes: `./bin/install-agents.sh`
- Run `./bin/sync-agents.sh` afterwards to refresh symlinks.

### `bin/sync-agents.sh`
- Treats `ai-agents/` as the canonical, Git-tracked source of truth for global AI agent tooling config, and symlinks it directly into each tool's real global config location (not into `xdg/`/`home/`, which only support one destination per source):
  - `ai-agents/AGENTS.md` → `~/.copilot/copilot-instructions.md`, `~/.config/opencode/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.kiro/steering/AGENTS.md`
  - `ai-agents/agents/<name>.md` → `~/.copilot/agents/<name>.agent.md`, `~/.config/opencode/agents/<name>.md`, `~/.claude/agents/<name>.md`
  - `ai-agents/skills/<name>/` → `~/.agents/skills/<name>` (GitHub Copilot and OpenCode), `~/.claude/skills/<name>` (Claude Code), `~/.kiro/skills/<name>` (Kiro CLI)
- **Known gap**: Kiro CLI's global agents are JSON files with a `prompt` string field (see `kiro-cli agent create`), not markdown+frontmatter like the other tools, so `ai-agents/agents/<name>.md` is not synced there. Kiro still gets skills and instructions (via `~/.kiro/steering/`).
- Skills disabled in `ai-agents/config.yaml` have their symlink removed on next sync.
- Never symlinks or replaces an entire agent `skills/`/`agents/` directory, so entries managed outside this repository can coexist; only touches symlinks it created that still point into this repo.
- Must support the repository's standard dry-run behavior:
  - Dry run (preview changes without applying): `./bin/sync-agents.sh --dry-run`
  - Apply changes: `./bin/sync-agents.sh`

### `bin/install-tool.sh`

- parameter: 
  - name: (mandatory) tool name
- parse config files to get tools that are enabled with `install` commands defined
- execute install commands for the current OS

### `bin/install-all-tools.sh`

- parse config files to get all tools that are enabled with `install` commands defined
- invoke `bin/install-tool.sh` for each tool, respecting `install-priority` to ensure correct installation order

### `lib/utils.sh`

Shared utility functions used across `bin/` and other `lib/` scripts. Source it at the top of any script that needs it:
```sh
source "$(dirname "$0")/../lib/utils.sh"
```

### `lib/install.sh`

Functions related to installing/upgrading tools defined in config files. For example:
```sh
git-install <repo_url>
```

### `lib/bootstrap.sh`

- bootstrap all enabled tools with `bootstrap` commands and respective OS defined in config files,
- respecting `bootstrap-priority` to ensure correct execution order
- meant to be sourced in shell bootstrap files (e.g. `.zshrc`) in shell. For example, the below command can be added to `.zshrc` to bootstrap enabled tools :
    ```sh
    export CONFIG_HOME="$HOME/opt/config"
    source "$CONFIG_HOME/lib/bootstrap.sh"
    ```

