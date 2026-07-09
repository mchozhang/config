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

`config.yaml` defines tools to install and their config.
each tool has below properties:
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

### `bin/install-tool.sh`

- parameter: 
  - name: (mandatory) tool name
- parse `config.yaml` to get tools that are enabled with `install` commands defined
- execute install commands for the current OS

### `bin/install-all-tools.sh`

- parse `config.yaml` to get all tools that are enabled with `install` commands defined
- invoke `bin/install-tool.sh` for each tool, respecting `install-priority` to ensure correct installation order

### `lib/utils.sh`

Shared utility functions used across `bin/` and other `lib/` scripts. Source it at the top of any script that needs it:
```sh
source "$(dirname "$0")/../lib/utils.sh"
```

### `lib/install.sh`

Functions related to installing/upgrading tools defined in `config.yaml`. For example:
```sh
git-install <repo_url>
```

### `lib/bootstrap.sh`

- bootstrap all enabled tools with `bootstrap` commands and respective OS defined in `config.yaml`,
- respecting `bootstrap-priority` to ensure correct execution order
- meant to be sourced in shell bootstrap files (e.g. `.zshrc`) in shell. For example, the below command can be added to `.zshrc` to bootstrap enabled tools :
    ```sh
    export CONFIG_HOME="$HOME/opt/config"
    source "$CONFIG_HOME/lib/bootstrap.sh"
    ```


