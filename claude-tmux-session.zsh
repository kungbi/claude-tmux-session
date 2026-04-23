# claude-tmux-session.zsh
# Claude Code tmux session manager (macOS)

_CLAUDE_TMUX_VERSION="0.2.17"

# Returns the first user message for a session from ~/.claude/history.jsonl
_claude_tmux_session_title() {
  local uuid="$1"
  [[ -z "$uuid" ]] && return
  local history_file="${HOME}/.claude/history.jsonl"
  [[ -f "$history_file" ]] || return
  python3 -c "
import json, sys
uuid = sys.argv[1]
with open(sys.argv[2]) as f:
    for line in f:
        try:
            obj = json.loads(line)
            if obj.get('sessionId') == uuid:
                d = obj.get('display', '').strip()
                if d:
                    print(d[:50])
                    sys.exit(0)
        except:
            pass
" "$uuid" "$history_file" 2>/dev/null
}

_claude_tmux() {
  local dir_hash="claude_$(echo "$PWD" | md5 -q | head -c 8)"
  local stamp_dir="${HOME}/.cache/claude-sessions"
  local session_ttl=300

  mkdir -p "$stamp_dir"

  if [[ -f "${stamp_dir}/.disabled" ]]; then
    command claude "$@"
    return
  fi

  # --dangerously-load-development-channels requires resources bound to the current
  # shell session (IPC sockets etc.) that don't survive a new tmux session
  local _arg
  for _arg in "$@"; do
    if [[ "$_arg" == --dangerously-load-development-channels* ]]; then
      command claude "$@"
      return
    fi
  done

  if [[ -z "$TMUX" ]]; then
    local s stamp_file sname all_sessions valid_sessions=() now elapsed saved_raw saved session_uuid
    all_sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${dir_hash}"))
    now=$(date +%s)

    # clean up orphaned stamp files (stamp exists but tmux session does not)
    for stamp_file in "$stamp_dir"/${dir_hash}_*(N); do
      sname="${stamp_file##*/}"
      tmux has-session -t "$sname" 2>/dev/null || rm -f "$stamp_file"
    done

    for s in "${all_sessions[@]}"; do
      if [[ -f "$stamp_dir/$s" ]]; then
        saved_raw=$(< "$stamp_dir/$s")
        # Parse {timestamp}:{uuid} or legacy {timestamp}
        if [[ "$saved_raw" == *:* ]]; then
          saved="${saved_raw%%:*}"
        else
          saved="$saved_raw"
        fi
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
          saved_raw=$(< "$stamp_dir/$s")
          if [[ "$saved_raw" == *:* ]]; then
            saved="${saved_raw%%:*}"
            session_uuid="${saved_raw#*:}"
          else
            saved="$saved_raw"
            session_uuid=""
          fi
          elapsed=$((now - saved))
          local mins=$(( elapsed / 60 )) secs=$(( elapsed % 60 ))
          local time_str="${secs} sec ago"
          (( mins > 0 )) && time_str="${mins} min ago"
          local title=$(_claude_tmux_session_title "$session_uuid")
          if [[ -n "$title" ]]; then
            printf '  [%d] "%s" - %s\n' $i "$title" "$time_str"
          else
            printf '  [%d] %s\n' $i "$time_str"
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
        # Preserve UUID when updating stamp timestamp after re-attach
        local existing_raw=$(< "$stamp_dir/$selected")
        local existing_uuid=""
        [[ "$existing_raw" == *:* ]] && existing_uuid="${existing_raw#*:}"
        if [[ -n "$existing_uuid" ]]; then
          echo "$(date +%s):${existing_uuid}" > "$stamp_dir/$selected"
        else
          echo "$(date +%s)" > "$stamp_dir/$selected"
        fi
        return
      fi
    fi

    local session_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local new_key="${dir_hash}_$(date +%s)_$$"
    local claude_args=${(q-)@}
    tmux new-session -s "$new_key" "command claude --session-id ${session_uuid} ${claude_args}; echo \"\$(date +%s):${session_uuid}\" > \"${stamp_dir}/${new_key}\""
    echo "$(date +%s):${session_uuid}" > "$stamp_dir/$new_key"
  else
    command claude "$@"
  fi
}

claude() { _claude_tmux "$@" }
