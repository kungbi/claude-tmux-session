# claude-tmux-session

Claude Code tmux session manager for zsh (macOS).  
zsh용 Claude Code tmux 세션 매니저 (macOS).

Automatically runs `claude` inside a tmux session and offers to resume your previous session when you return to the same directory within 5 minutes.  
`claude` 실행 시 자동으로 tmux 세션 안에서 시작하고, 5분 이내에 같은 디렉토리로 돌아오면 이전 세션을 이어서 사용할 수 있습니다.

## Features / 기능

- Runs `claude` inside a named tmux session automatically — 자동으로 tmux 세션 안에서 실행
- Lists previous sessions when reopening in the same directory within 5 minutes — 5분 이내 재실행 시 이전 세션 목록 표시
- Supports multiple sessions per directory — 디렉토리별 여러 세션 지원
- Session auto-expires after 5 minutes of inactivity — 5분 비활성 시 자동 만료
- Works inside existing tmux sessions without nesting — 기존 tmux 안에서는 중첩 없이 바로 실행

## Requirements / 요구사항

- [tmux](https://github.com/tmux/tmux)
- [Claude Code](https://claude.ai/code)
- zsh (macOS)

## Installation / 설치

### Homebrew (recommended / 권장)

```zsh
brew tap kungbi/claude-tmux
brew install claude-tmux-session
echo 'source "$(brew --prefix)/share/claude-tmux-session/claude-tmux-session.zsh"' >> ~/.zshrc && source ~/.zshrc
```

### Manual / 수동 설치

```zsh
curl -fsSL https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/install.sh | zsh
source ~/.zshrc
```

## Usage / 사용법

Just use `claude` as you normally would:  
평소처럼 `claude`를 실행하면 됩니다:

```zsh
claude
```

When you return to the same directory within 5 minutes after closing, you'll see a session list:  
종료 후 5분 이내에 같은 디렉토리에서 다시 실행하면 세션 목록이 표시됩니다:

```
[claude] Session list: ~/your/project
  [1] 2 min ago
  [2] active session
  [n] new session
  [q] cancel
select:
```

Press a number to resume, `n` for a new session, or `q` to cancel.  
번호를 눌러 세션 복원, `n`으로 새 세션 생성, `q`로 취소.

## CLI

```zsh
claude-tmux version        # show current version / 현재 버전 출력
claude-tmux update         # update to latest version / 최신 버전으로 업데이트
claude-tmux ls             # list active sessions / 활성 세션 목록
claude-tmux kill           # kill all idle sessions / idle 세션 전체 종료
claude-tmux kill <n>       # kill session by index / n번 세션 종료
claude-tmux clean          # remove expired stamp files / 만료된 stamp 파일 정리
claude-tmux alias <name>   # register a short alias / 단축키 등록 (예: ct)
claude-tmux on             # enable session manager / 세션 매니저 활성화
claude-tmux off            # disable session manager / 세션 매니저 비활성화
```

`claude-tmux update` runs `brew update && brew upgrade` when installed via Homebrew, or downloads directly for manual installs.  
Homebrew로 설치한 경우 `brew update && brew upgrade`를 실행하고, 수동 설치의 경우 직접 다운로드합니다.

### Session list (`ls`)

```
[1] claude_099dbc31_... (running, 5m 12s elapsed)
[2] claude_85225192_... (idle, 2h 4m elapsed)
[3] claude_e7d7a0db_... (idle, 6h 31m elapsed)
```

- **running** — Claude Code is currently active in this session / 현재 Claude Code가 실행 중인 세션
- **idle** — session exists in the background / 백그라운드에 대기 중인 세션 (Claude 종료 또는 분리됨)
- **elapsed** — time since the session was created / 세션 생성 후 경과 시간
- Use `claude-tmux kill <n>` to remove a session by its index number / `claude-tmux kill <n>`으로 번호 지정 종료

## Aliases / 별칭

Any alias that calls `claude` automatically goes through the session manager — no extra steps needed:  
`claude`를 호출하는 alias는 자동으로 세션 매니저를 거칩니다:

```zsh
alias cc='claude --dangerously-skip-permissions'
alias ccc='claude --dangerously-skip-permissions --channels your-channel'
```

단축키를 등록하려면:

```zsh
claude-tmux alias ct   # ct를 claude-tmux의 단축키로 등록
source ~/.zshrc
```

## Tip: Hide tmux status bar / tmux 상태바 숨기기

Add to `~/.tmux.conf` / `~/.tmux.conf`에 추가:

```
set -g status off
```
