English | [한국어](README.ko.md)

# claude-tmux-session

[![GitHub stars](https://img.shields.io/github/stars/kungbi/claude-tmux-session?style=flat&color=yellow)](https://github.com/kungbi/claude-tmux-session/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Homebrew](https://img.shields.io/badge/Homebrew-available-orange?logo=homebrew)](https://github.com/kungbi/homebrew-claude-tmux)

> Claude Code tmux session manager for zsh (macOS).

**Never lose a Claude Code session again.**

_Run `claude`. Close your terminal. Come back. Pick up where you left off._

[Installation](#installation) • [Usage](#usage) • [CLI Reference](#cli) • [Compatibility](#compatibility)

<img width="620" alt="image" src="https://github.com/user-attachments/assets/7c5d486b-9d45-430f-8e55-cfed62ff80bd" />

---

## Features

- Automatically runs `claude` inside a named tmux session
- Lists resumable sessions when reopening in the same directory within 5 minutes
- Supports multiple sessions per directory
- Sessions auto-expire after 5 minutes of inactivity
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
  [1] "Implement auth middleware" - 2 min ago
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
claude-tmux uninstall      # remove claude-tmux-session completely
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

## Compatibility

### cmux

If you use [cmux](https://cmux.com), run this once to allow `cmux` CLI commands inside tmux sessions created by claude-tmux-session:

```zsh
defaults write com.cmuxterm.app socketControlMode -string "allowAll"
```

Then restart cmux. See [PR #12](https://github.com/kungbi/claude-tmux-session/pull/12) for details.

---

<div align="center">

**Never lose a session. Never lose your flow.**

</div>
