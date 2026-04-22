# Changelog

## [0.3.0] — 2026-04-22

### Added

- **Split-pane watcher** (`--watch` flag / `claude-tmux watch on`): opt-in feature that splits the terminal 70/30 and displays live `git diff --stat`, `git status --short`, and recent file edits (last 10m) in the right pane while claude runs in the left pane.
- `claude-tmux watch on|off|status` subcommand for persistent toggle.
- `--watch` / `--no-watch` per-invocation flags (stripped before forwarding to claude).
- `bin/claude-watch` standalone polling renderer with Layer 3 self-watchdog (`--claude-pane <id>`).
- **3-layer defense-in-depth cleanup** — watcher pane is removed within `watcher_interval` (default 2s) for all exit modes including `kill -9`:
  1. Layer 1: trailing inline `tmux kill-pane` after claude exits (primary).
  2. Layer 2: `set-hook -w pane-exited` window-scope hook with `#{hook_pane}` guard (secondary).
  3. Layer 3: watcher self-watchdog via `tmux list-panes` polling (tertiary, covers `kill -9`).
- tmux >= 2.4 required for watcher (install warns if older; basic features unaffected).

### Notes

- Watcher is **off by default** — zero behavior change for existing users.
- Watcher gracefully no-ops when not in a git repo, tmux is missing/too old, or watcher script is not found.
- tmux server kill remains acceptable loss (both panes vanish with the server).
