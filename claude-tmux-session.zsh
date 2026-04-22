# claude-tmux-session.zsh
# Claude Code tmux session manager (macOS)

_CLAUDE_TMUX_VERSION="0.2.13"

_claude_tmux() {
  local dir_hash="claude_$(echo "$PWD" | md5 -q | head -c 8)"
  local stamp_dir="${HOME}/.cache/claude-sessions"
  local session_ttl=300

  mkdir -p "$stamp_dir"

  if [[ -f "${stamp_dir}/.disabled" ]]; then
    command claude "$@"
    return
  fi

  # bypass tmux for dev-channel invocations (e.g. --dangerously-load-development-channels)
  # those servers are bound to the current shell environment and won't survive a new tmux session
  local _arg
  for _arg in "$@"; do
    if [[ "$_arg" == --dangerously-load-development-channels* ]]; then
      command claude "$@"
      return
    fi
  done

  if [[ -z "$TMUX" ]]; then
    local s stamp_file sname all_sessions valid_sessions=() now elapsed saved
    all_sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${dir_hash}"))
    now=$(date +%s)

    # clean up orphaned stamp files (stamp exists but tmux session does not)
    for stamp_file in "$stamp_dir"/${dir_hash}_*(N); do
      sname="${stamp_file##*/}"
      tmux has-session -t "$sname" 2>/dev/null || rm -f "$stamp_file"
    done

    for s in "${all_sessions[@]}"; do
      if [[ -f "$stamp_dir/$s" ]]; then
        saved=$(< "$stamp_dir/$s")
        elapsed=$((now - saved))
        if (( elapsed >= session_ttl )); then
          tmux kill-session -t "$s" 2>/dev/null
          rm -f "$stamp_dir/$s"
          continue
        fi
      fi
      valid_sessions+=("$s")
    done

    if (( ${#valid_sessions[@]} > 0 )); then
      printf '\033[1;36m[claude]\033[0m Session list: %s\n' "${PWD/#$HOME/~}"
      local i=1
      for s in "${valid_sessions[@]}"; do
        if [[ -f "$stamp_dir/$s" ]]; then
          saved=$(< "$stamp_dir/$s")
          elapsed=$((now - saved))
          local mins=$(( elapsed / 60 ))
          local secs=$(( elapsed % 60 ))
          if (( mins > 0 )); then
            printf '  [%d] %d min ago\n' $i $mins
          else
            printf '  [%d] %d sec ago\n' $i $secs
          fi
        else
          printf '  [%d] active session\n' $i
        fi
        i=$((i + 1))
      done
      printf '  [n] new session\n'
      printf '  [q] cancel\n'
      printf 'select: '
      read -k 1 choice
      printf '\n'

      if [[ "$choice" =~ ^[qQ]$ ]]; then
        return
      fi

      if [[ "$choice" =~ ^[1-9]$ ]] && (( choice >= 1 && choice <= ${#valid_sessions[@]} )); then
        local selected="${valid_sessions[$choice]}"
        tmux attach-session -t "$selected"
        echo $(date +%s) > "$stamp_dir/$selected"
        return
      fi
    fi

    local new_key="${dir_hash}_$(date +%s)_$$"
    local claude_args=${(q-)@}
    tmux new-session -s "$new_key" "command claude $claude_args; echo \$(date +%s) > \"$stamp_dir/$new_key\""
    echo $(date +%s) > "$stamp_dir/$new_key"
  else
    command claude "$@"
  fi
}

claude() { _claude_tmux "$@" }
