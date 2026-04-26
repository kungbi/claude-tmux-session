[English](README.md) | 한국어

# claude-tmux-session

[![GitHub stars](https://img.shields.io/github/stars/kungbi/claude-tmux-session?style=flat&color=yellow)](https://github.com/kungbi/claude-tmux-session/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Homebrew](https://img.shields.io/badge/Homebrew-available-orange?logo=homebrew)](https://github.com/kungbi/homebrew-claude-tmux)

> zsh용 Claude Code tmux 세션 매니저 (macOS).

**Claude Code 세션을 다시는 잃어버리지 마세요.**

_`claude` 실행 → 터미널 닫기 → 돌아오기 → 이어서 작업._

[설치](#설치) • [사용법](#사용법) • [CLI 레퍼런스](#cli) • [호환성](#호환성)

<img width="620" alt="image" src="https://github.com/user-attachments/assets/7c5d486b-9d45-430f-8e55-cfed62ff80bd" />

---

## 기능

- `claude` 실행 시 자동으로 tmux 세션 안에서 실행
- 5분 이내 재실행 시 이전 세션 목록 표시
- 디렉토리별 여러 세션 지원
- 5분 비활성 시 자동 만료
- 기존 tmux 안에서는 중첩 없이 바로 실행

## 요구사항

- [tmux](https://github.com/tmux/tmux)
- [Claude Code](https://claude.ai/code)
- zsh (macOS)

## 설치

### Homebrew (권장)

```zsh
brew tap kungbi/claude-tmux
brew install claude-tmux-session
echo 'source "$(brew --prefix)/share/claude-tmux-session/claude-tmux-session.zsh"' >> ~/.zshrc && source ~/.zshrc
```

### 수동 설치

```zsh
curl -fsSL https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/install.sh | zsh
source ~/.zshrc
```

## 사용법

평소처럼 `claude`를 실행하면 됩니다:

```zsh
claude
```

종료 후 5분 이내에 같은 디렉토리에서 다시 실행하면 세션 목록이 표시됩니다:

```
[claude] Session list: ~/your/project
  [1] "인증 미들웨어 구현" - 2분 전
  [2] 활성 세션
  [n] 새 세션 생성
  [q] 취소
select:
```

번호를 눌러 세션 복원, `n`으로 새 세션 생성, `q`로 취소.

## CLI

```zsh
claude-tmux version        # 현재 버전 출력
claude-tmux update         # 최신 버전으로 업데이트
claude-tmux ls             # 활성 세션 목록 (번호 및 경과 시간 표시)
claude-tmux kill           # idle 세션 전체 종료 (확인 후)
claude-tmux kill <n>       # n번 세션 종료
claude-tmux clean          # 만료된 stamp 파일 정리
claude-tmux alias <name>   # 단축키 등록 (예: ct)
claude-tmux on             # 세션 매니저 활성화
claude-tmux off            # 세션 매니저 비활성화
claude-tmux uninstall      # claude-tmux-session 완전 제거
```

`claude-tmux update`는 Homebrew로 설치한 경우 `brew update && brew upgrade`를 실행하고, 수동 설치의 경우 직접 다운로드합니다.

### 세션 목록 (`ls`)

```
[1] claude_099dbc31_... (running, 5m 12s elapsed)
[2] claude_85225192_... (idle, 2h 4m elapsed)
[3] claude_e7d7a0db_... (idle, 6h 31m elapsed)
```

- **running** — 현재 Claude Code가 실행 중인 세션
- **idle** — 백그라운드에 대기 중인 세션 (Claude 종료 또는 분리됨)
- **elapsed** — 세션 생성 후 경과 시간
- `claude-tmux kill <n>`으로 번호를 지정해 종료 가능

## 별칭 (Alias)

`claude`를 호출하는 alias는 자동으로 세션 매니저를 거칩니다:

```zsh
alias cc='claude --dangerously-skip-permissions'
alias ccc='claude --dangerously-skip-permissions --channels your-channel'
```

단축키를 등록하려면:

```zsh
claude-tmux alias ct
source ~/.zshrc
```

## 호환성

### cmux

[cmux](https://cmux.com)를 사용하는 경우, tmux 세션 안에서 `cmux` CLI가 동작하려면 아래 명령어를 한 번 실행하세요:

```zsh
defaults write com.cmuxterm.app socketControlMode -string "allowAll"
```

설정 후 cmux를 재시작하세요. 자세한 내용은 [PR #12](https://github.com/kungbi/claude-tmux-session/pull/12)를 참고하세요.

---

<div align="center">

**세션을 잃지 마세요. 흐름을 잃지 마세요.**

</div>
