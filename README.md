# claude-tmux-session

Claude Code tmux session manager for zsh (macOS).

Automatically runs `claude` inside a tmux session and offers to resume your previous session when you return to the same directory within 5 minutes.

[한국어 README](README.ko.md)

## Features

- Runs `claude` inside a named tmux session automatically
- Lists previous sessions when reopening in the same directory within 5 minutes
- Supports multiple sessions per directory
- Session auto-expires after 5 minutes of inactivity
- Works inside existing tmux sessions without nesting

## Requirements

- [tmux](https://github.com/tmux/tmux)
- [Claude Code](https://claude.ai/code)
- zsh (macOS)

## Installation

### Homebrew (recommended)

```zsh
brew tap kungbi/claude-tmux
brew install claude-tmux-session
echo 'source "$(brew --prefix)/share/claude-tmux-session/claude-tmux-session.zsh"' >> ~/.zshrc && source ~/.zshrc
```

### Manual

```zsh
curl -fsSL https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/install.sh | zsh
source ~/.zshrc
```

## Usage

Just use `claude` as you normally would:

```zsh
claude
```

When you return to the same directory within 5 minutes after closing, you'll see a session list:

```
[claude] Session list: ~/your/project
  [1] 2 min ago
  [2] active session
  [n] new session
  [q] cancel
select:
```

Press a number to resume, `n` for a new session, or `q` to cancel.

## CLI

```zsh
claude-tmux version        # show current version
claude-tmux update         # update to latest version
claude-tmux ls             # list active sessions with index and elapsed time
claude-tmux kill           # kill all idle sessions (with confirmation)
claude-tmux kill <n>       # kill session by index number
claude-tmux clean          # remove expired stamp files
claude-tmux alias <name>   # register a short alias (e.g. ct)
claude-tmux on             # enable session manager
claude-tmux off            # disable session manager
```

`claude-tmux update` runs `brew update && brew upgrade` when installed via Homebrew, or downloads directly for manual installs.

### Session list (`ls`)

```
[1] claude_099dbc31_... (running, 5m 12s elapsed)
[2] claude_85225192_... (idle, 2h 4m elapsed)
[3] claude_e7d7a0db_... (idle, 6h 31m elapsed)
```

- **running** — Claude Code is currently active in this session
- **idle** — session exists in the background (Claude exited or detached)
- **elapsed** — time since the session was created
- Use `claude-tmux kill <n>` to remove a session by its index number

## Aliases

Any alias that calls `claude` automatically goes through the session manager — no extra steps needed:

```zsh
alias cc='claude --dangerously-skip-permissions'
alias ccc='claude --dangerously-skip-permissions --channels your-channel'
```

To register a short alias:

```zsh
claude-tmux alias ct
source ~/.zshrc
```

## Tip: Hide tmux status bar

Add to `~/.tmux.conf`:

```
set -g status off
```
