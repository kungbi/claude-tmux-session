# claude-tmux-session.zsh
# Claude Code tmux session manager
#
# Usage:
#   source <(curl -s https://gist.githubusercontent.com/.../raw/claude-tmux-session.zsh)
#
# Features:
#   - Runs claude inside a tmux session automatically
#   - Offers y/n resume prompt when returning to the same directory within 5 min
#   - Session auto-expires after 5 minutes of inactivity

_claude_tmux() {
  local session_key="claude_$(echo "$PWD" | md5 -q | head -c 8)"
  local stamp_file="${HOME}/.cache/claude-sessions/${session_key}"
  local session_ttl=300

  mkdir -p "${HOME}/.cache/claude-sessions"

  if [ -z "$TMUX" ]; then
    if tmux has-session -t "$session_key" 2>/dev/null; then
      local now saved=0 elapsed
      now=$(date +%s)
      [[ -f "$stamp_file" ]] && saved=$(cat "$stamp_file")
      elapsed=$((now - saved))

      if (( elapsed < session_ttl )) || [[ ! -f "$stamp_file" ]]; then
        printf '\033[1;36m[claude]\033[0m 이전 세션 발견: %s\n' "${PWD/#$HOME/~}"
        printf '재개하시겠습니까? (y/n): '
        read -k 1 answer
        printf '\n'
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
          tmux attach-session -t "$session_key"
          echo $(date +%s) > "$stamp_file"
          return
        fi
      fi

      tmux kill-session -t "$session_key" 2>/dev/null
      rm -f "$stamp_file"
    fi

    tmux new-session -s "$session_key" "command claude $*; echo \$(date +%s) > \"$stamp_file\""
    echo $(date +%s) > "$stamp_file"
  else
    command claude "$@"
  fi
}

claude() { _claude_tmux "$@" }
