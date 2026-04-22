#!/bin/zsh
# claude-tmux-session installer

set -e

SCRIPT_URL="https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/claude-tmux-session.zsh"
BIN_URL="https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/bin/claude-tmux"
INSTALL_DIR="${HOME}/.local/share/claude-tmux-session"
INSTALL_PATH="${INSTALL_DIR}/claude-tmux-session.zsh"
BIN_DIR="${HOME}/.local/bin"
BIN_PATH="${BIN_DIR}/claude-tmux"
BIN_WATCH_URL="https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/bin/claude-watch"
BIN_WATCH_PATH="${BIN_DIR}/claude-watch"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
SOURCE_LINE="source \"${INSTALL_PATH}\""
PATH_LINE="export PATH=\"\${HOME}/.local/bin:\${PATH}\""

_info()    { printf '\033[1;36m[claude-tmux]\033[0m %s\n' "$1"; }
_success() { printf '\033[1;32m[claude-tmux]\033[0m %s\n' "$1"; }
_warn()    { printf '\033[1;33m[claude-tmux]\033[0m %s\n' "$1"; }
_error()   { printf '\033[1;31m[claude-tmux]\033[0m %s\n' "$1"; }

if ! command -v tmux &>/dev/null; then
  _error "tmux가 설치되어 있지 않습니다. brew install tmux"
  exit 1
fi
if ! command -v claude &>/dev/null; then
  _error "Claude Code가 설치되어 있지 않습니다. https://claude.ai/code"
  exit 1
fi

# tmux version check (warn only, do not abort)
_tmux_version_warn() {
  local v major minor
  v=$(tmux -V 2>/dev/null | awk '{print $2}')
  v="${v%%[!0-9.]*}"
  major="${v%%.*}"; minor="${v#*.}"; minor="${minor%%.*}"
  if ! { (( major > 2 )) || (( major == 2 && minor >= 4 )); }; then
    _warn "tmux 2.4+ required for the optional split-pane watcher; basic claude-tmux features will work, but --watch will no-op."
  fi
}
_tmux_version_warn

_info "다운로드 중..."
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

if ! curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"; then
  _error "다운로드 실패 (claude-tmux-session.zsh)"
  exit 1
fi

if ! curl -fsSL "$BIN_URL" -o "$BIN_PATH"; then
  _error "다운로드 실패 (claude-tmux)"
  exit 1
fi
chmod +x "$BIN_PATH"

if ! curl -fsSL "$BIN_WATCH_URL" -o "$BIN_WATCH_PATH"; then
  _warn "claude-watch 다운로드 실패 (watcher 기능 비활성화됨; 나머지 기능은 정상 동작)"
else
  chmod +x "$BIN_WATCH_PATH"
fi

if grep -qF "$PATH_LINE" "$ZSHRC" 2>/dev/null || [[ ":$PATH:" == *":${BIN_DIR}:"* ]]; then
  true
else
  printf '\n%s\n' "$PATH_LINE" >> "$ZSHRC"
fi

if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
  _warn "이미 설치되어 있습니다 ($ZSHRC)"
else
  printf '\n# claude-tmux-session\n%s\n' "$SOURCE_LINE" >> "$ZSHRC"
  _success "~/.zshrc에 추가 완료"
fi

_success "설치 완료!"
_info "적용: source ~/.zshrc"
_info "업데이트: claude-tmux update"
