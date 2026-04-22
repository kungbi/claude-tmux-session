# claude-tmux-session

Claude Code tmux session manager for zsh (macOS).

Automatically runs `claude` inside a tmux session and offers to resume your previous session when you return to the same directory within 5 minutes.

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
brew tap kungbi/claude-tmux https://github.com/kungbi/kungbi-homebrew-claude-tmux
brew install claude-tmux-session
```

Then add to `~/.zshrc`:

```zsh
source "$(brew --prefix)/share/claude-tmux-session/claude-tmux-session.zsh"
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
[claude] 세션 목록: ~/your/project
  [1] 2분 전
  [2] 활성 세션
  [n] 새 세션 생성
  [q] 취소
선택:
```

Press a number to resume, `n` for a new session, or `q` to cancel.

## CLI

```zsh
claude-tmux version   # show current version
claude-tmux update    # update to latest version
claude-tmux status    # list active sessions
claude-tmux clean     # remove expired stamp files
```

`claude-tmux update` runs `brew upgrade` when installed via Homebrew, or downloads directly for manual installs.

## Aliases

The plugin wraps the `claude` command. If you have aliases like `cc` or `ccc`, wrap them as well:

```zsh
alias cc='claude --dangerously-skip-permissions'
alias ccc='claude --dangerously-skip-permissions --channels your-channel'
```

## Tip: Hide tmux status bar

If you don't want the tmux status bar to appear, add this to `~/.tmux.conf`:

```
set -g status off
```
