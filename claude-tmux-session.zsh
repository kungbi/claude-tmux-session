# claude-tmux-session.zsh
# Claude Code tmux session manager
#
# Usage:
#   source <(curl -s https://raw.githubusercontent.com/kungbi/claude-tmux-session/main/claude-tmux-session.zsh)
#
# Features:
#   - Runs claude inside a tmux session automatically
#   - Lists previous sessions when returning to the same directory within 5 min
#   - Supports multiple sessions per directory
#   - Session auto-expires after 5 minutes of inactivity

_claude_tmux() {
  local dir_hash="claude_$(echo "$PWD" | md5 -q | head -c 8)"
  local stamp_dir="${HOME}/.cache/claude-sessions"
  local session_ttl=300

  mkdir -p "$stamp_dir"

  if [ -z "$TMUX" ]; then
    local all_sessions valid_sessions=() now elapsed saved
    all_sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${dir_hash}"))
    now=$(date +%s)

    for s in "${all_sessions[@]}"; do
      saved=0
      [[ -f "$stamp_dir/$s" ]] && saved=$(cat "$stamp_dir/$s")
      elapsed=$((now - saved))
      if (( elapsed < session_ttl )) || [[ ! -f "$stamp_dir/$s" ]]; then
        valid_sessions+=("$s")
      else
        tmux kill-session -t "$s" 2>/dev/null
        rm -f "$stamp_dir/$s"
      fi
    done

    if (( ${#valid_sessions[@]} > 0 )); then
      printf '\033[1;36m[claude]\033[0m 세션 목록: %s\n' "${PWD/#$HOME/~}"
      local i=1
      for s in "${valid_sessions[@]}"; do
        saved=0
        [[ -f "$stamp_dir/$s" ]] && saved=$(cat "$stamp_dir/$s")
        elapsed=$((now - saved))
        local mins=$(( elapsed / 60 ))
        local secs=$(( elapsed % 60 ))
        if (( mins > 0 )); then
          printf '  [%d] %d분 전\n' $i $mins
        else
          printf '  [%d] %d초 전\n' $i $secs
        fi
        i=$((i + 1))
      done
      printf '  [n] 새 세션 생성\n'
      printf '  [q] 취소\n'
      printf '선택: '
      read -k 1 choice
      printf '\n'

      if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        return
      fi

      if [[ "$choice" =~ ^[1-9]$ ]] && (( choice >= 1 && choice <= ${#valid_sessions[@]} )); then
        local selected="${valid_sessions[$choice]}"
        tmux attach-session -t "$selected"
        echo $(date +%s) > "$stamp_dir/$selected"
        return
      fi
    fi

    local new_key="${dir_hash}_$(date +%s | tail -c 5)"
    tmux new-session -s "$new_key" "command claude $*; echo \$(date +%s) > \"$stamp_dir/$new_key\""
    echo $(date +%s) > "$stamp_dir/$new_key"
  else
    command claude "$@"
  fi
}

claude() { _claude_tmux "$@" }
