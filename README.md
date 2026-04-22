# claude-tmux-session

Claude Code tmux session manager for zsh.

Automatically runs `claude` inside a tmux session and offers to resume your previous session when you return to the same directory within 5 minutes.

## Features

- Runs `claude` inside a named tmux session automatically
- Detects previous session when reopening in the same directory
- Prompts `y/n` to resume within a 5-minute window
- Session auto-expires after 5 minutes of inactivity
- Works inside existing tmux sessions without nesting

## Requirements

- [tmux](https://github.com/tmux/tmux)
- [Claude Code](https://claude.ai/code)
- zsh

## Installation

Add to your `~/.zshrc`:

```zsh
source <(curl -s https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/claude-tmux-session.zsh)
```

## Usage

Just use `claude` as you normally would:

```zsh
claude
```

When you return to the same directory within 5 minutes after closing, you'll see:

```
[claude] 이전 세션 발견: ~/your/project
재개하시겠습니까? (y/n):
```

Press `y` to resume, `n` to start a new session.

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
