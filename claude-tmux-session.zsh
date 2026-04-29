# claude-tmux-session.zsh
# Claude Code tmux session manager (macOS)

_CLAUDE_TMUX_VERSION="0.5.1"

# Returns the last user prompt for a session from ~/.claude/projects/{slug}/{uuid}.jsonl
_claude_tmux_session_title() {
  local uuid="$1"
  local pwd="$2"
  [[ -z "$uuid" || -z "$pwd" ]] && return
  local slug="${pwd//[^a-zA-Z0-9]/-}"
  local session_file="${HOME}/.claude/projects/${slug}/${uuid}.jsonl"
  [[ -f "$session_file" ]] || return
  python3 -c "
import json, sys
last = None
with open(sys.argv[1]) as f:
    for line in f:
        try:
            obj = json.loads(line)
            if obj.get('type') == 'last-prompt':
                d = obj.get('lastPrompt', '').strip()
                if d:
                    last = d
        except:
            pass
if last:
    print(last.replace('\n', ' ')[:100])
" "$session_file" 2>/dev/null
}

_claude_tmux() {
  local dir_hash="claude_$(echo "$PWD" | md5 -q | head -c 8)"
  local stamp_dir="${HOME}/.cache/claude-sessions"
  local background_ttl=$(( 3 * 24 * 3600 ))

  mkdir -p "$stamp_dir"

  if [[ -f "${stamp_dir}/.disabled" ]]; then
    command claude "$@"
    return
  fi

  # --dangerously-load-development-channels and --channels require resources bound to the current
  # shell session (IPC sockets etc.) that don't survive a new tmux session
  local _arg
  for _arg in "$@"; do
    if [[ "$_arg" == --dangerously-load-development-channels* || "$_arg" == --channels* ]]; then
      command claude "$@"
      return
    fi
  done

  if [[ -z "$TMUX" ]]; then
    local s stamp_file sname all_sessions valid_sessions=() now elapsed
    all_sessions=($(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep "^${dir_hash}"))
    now=$(date +%s)

    # clean up orphaned stamp files (stamp exists but tmux session does not)
    for stamp_file in "$stamp_dir"/${dir_hash}_*(N); do
      sname="${stamp_file##*/}"
      tmux has-session -t "$sname" 2>/dev/null || rm -f "$stamp_file"
    done

    for s in "${all_sessions[@]}"; do
      local attached last_attached
      attached=$(tmux display-message -t "$s" -p "#{session_attached}" 2>/dev/null)
      if [[ "$attached" == "1" ]]; then
        valid_sessions+=("$s")
        continue
      fi
      last_attached=$(tmux display-message -t "$s" -p "#{session_last_attached}" 2>/dev/null)
      if [[ -n "$last_attached" && "$last_attached" -gt 0 ]]; then
        elapsed=$(( now - last_attached ))
        if (( elapsed >= background_ttl )); then
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
        local attached last_attached time_str title session_uuid=""
        attached=$(tmux display-message -t "$s" -p "#{session_attached}" 2>/dev/null)
        if [[ "$attached" == "1" ]]; then
          time_str="active"
        else
          last_attached=$(tmux display-message -t "$s" -p "#{session_last_attached}" 2>/dev/null)
          if [[ -n "$last_attached" && "$last_attached" -gt 0 ]]; then
            elapsed=$(( now - last_attached ))
            local mins=$(( elapsed / 60 )) hrs=$(( elapsed / 3600 ))
            if (( hrs > 0 )); then
              time_str="${hrs}h ago"
            elif (( mins > 0 )); then
              time_str="${mins} min ago"
            else
              time_str="${elapsed} sec ago"
            fi
          else
            time_str="background"
          fi
        fi
        if [[ -f "$stamp_dir/$s" ]]; then
          local saved_raw
          saved_raw=$(< "$stamp_dir/$s")
          [[ "$saved_raw" == *:* ]] && session_uuid="${saved_raw#*:}"
        fi
        title=$(_claude_tmux_session_title "$session_uuid" "$PWD")
        if [[ -n "$title" ]]; then
          printf '  [%d] "%s" - %s\n' $i "$title" "$time_str"
        else
          printf '  [%d] %s\n' $i "$time_str"
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
        return
      fi
    fi

    local session_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    local new_key="${dir_hash}_$(date +%s)_$$"
    local wrapper
    wrapper=$(mktemp "${stamp_dir}/.wrap.XXXXXX")
    {
      print -r -- '#!/bin/zsh'
      print -r -- "command claude --session-id ${(q)session_uuid} ${(q-)@}"
    } > "$wrapper"
    chmod +x "$wrapper"
    echo "$(date +%s):${session_uuid}" > "$stamp_dir/$new_key"
    tmux new-session -s "$new_key" -c "$PWD" "$wrapper"
    rm -f "$wrapper"
  else
    command claude "$@"
  fi
}

claude() { _claude_tmux "$@" }
