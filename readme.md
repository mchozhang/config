# Config


## prequitsite

* yq

```sh
# macos
brew install yq

# wsl ubuntu
sudo wget https://github.com/mikefarah/yq/releases/download/${VERSION}/yq_${PLATFORM} -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
```

* Node.js (for `npx`), required by `bin/install-agents.sh` to fetch skills

## AI agent config (`ai-agents/`)

`ai-agents/` is the source of truth for global AI agent tooling config (skills,
instructions, and subagents), shared across GitHub Copilot, OpenCode, Claude Code, and
Kiro CLI. See `.github/copilot-instructions.md` for the full schema and script details.

```sh
# fetch/upgrade skills listed in ai-agents/config.yaml
./bin/install-agents.sh

# symlink ai-agents/ content into each tool's global config location
./bin/sync-agents.sh
```