# claude-tmux-session.zsh
# Claude Code tmux session manager (macOS)

_CLAUDE_TMUX_VERSION="0.3.1"

# Returns 0 if watcher should be active for this invocation.
# Precedence: --no-watch flag > --watch flag > persistent stamp.
_claude_tmux_watch_enabled() {
  case "$_CLAUDE_TMUX_WATCH_OVERRIDE" in
    off) return 1 ;;
    on)  return 0 ;;
  esac
  [[ -f "${stamp_dir}/.watch-enabled" ]]
}

# Resolve absolute path to bin/claude-watch (next to this script).
_claude_tmux_watch_script() {
  local self="${(%):-%N}"
  local dir="${self:A:h}"
  print -r -- "${dir}/bin/claude-watch"
}

# Strip --watch / --no-watch from $@ and set _CLAUDE_TMUX_WATCH_OVERRIDE.
# Result is stored in _CLAUDE_TMUX_WATCH_ARGS array.
_claude_tmux_parse_watch_flag() {
  local out=() arg
  _CLAUDE_TMUX_WATCH_OVERRIDE=""
  for arg in "$@"; do
    case "$arg" in
      --watch)    _CLAUDE_TMUX_WATCH_OVERRIDE="on" ;;
      --no-watch) _CLAUDE_TMUX_WATCH_OVERRIDE="off" ;;
      *) out+=("$arg") ;;
    esac
  done
  _CLAUDE_TMUX_WATCH_ARGS=("${out[@]}")
}

# Check tmux version >= 2.4.
_claude_tmux_version_ok() {
  local v
  v="$(tmux -V 2>/dev/null | awk '{print $2}')" || return 1
  v="${v%%[!0-9.]*}"
  local major="${v%%.*}" minor="${v#*.}"; minor="${minor%%.*}"
  (( major > 2 )) || (( major == 2 && minor >= 4 ))
}

# Layer 2: window-scope pane-exited hook with #{hook_pane} guard + self-unregister.
# IMPORTANT: Do NOT use set-hook -p (pane scope) — it is a silent no-op on tmux 3.4 macOS.
# Only window scope (-w) is confirmed to fire.
_claude_tmux_attach_cleanup_hook() {
  local session="$1" claude_pane="$2" watcher_pane="$3"
  tmux set-hook -w -t "$session" pane-exited \
    "if -F '#{==:#{hook_pane},${claude_pane}}' \
      'kill-pane -t ${watcher_pane} ; set-hook -wu -t ${session} pane-exited'" \
    2>/dev/null
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
    local stamp_path="$stamp_dir/$new_key"

    # Parse --watch / --no-watch flags before proceeding
    _claude_tmux_parse_watch_flag "$@"

    local watcher_script
    watcher_script="$(_claude_tmux_watch_script)"

    local watcher_active=0
    if _claude_tmux_watch_enabled \
       && command -v tmux >/dev/null \
       && _claude_tmux_version_ok \
       && [[ -x "$watcher_script" ]]; then
      watcher_active=1
    elif _claude_tmux_watch_enabled; then
      print -u2 "claude-tmux: watcher requested but unavailable (tmux missing/old or watcher script not found); launching claude without watcher"
    fi

    if (( watcher_active )); then
      # Step 1: Create detached session with placeholder command
      tmux new-session -d -s "$new_key" -x "$(tput cols)" -y "$(tput lines)" \
        "sleep infinity"

      # Step 2: Capture claude pane id (stable %N id, not index)
      local claude_pane
      claude_pane="$(tmux display-message -p -t "$new_key" '#{pane_id}')"

      # Step 3: Split right 30%, capture watcher pane id, pass --claude-pane (Layer 3)
      local watcher_pane
      watcher_pane="$(tmux split-window -h -p 30 -t "$claude_pane" -P -F '#{pane_id}' \
        "$watcher_script --cwd $(printf %q "$PWD") --claude-pane $claude_pane")"

      # Step 4: Restore focus to claude pane
      tmux select-pane -t "$claude_pane"

      # Step 5: Layer 2 — window-scope hook with #{hook_pane} guard + self-unregister
      _claude_tmux_attach_cleanup_hook "$new_key" "$claude_pane" "$watcher_pane"

      # Step 6: Write real claude command to temp file to avoid shell quoting issues
      # Layer 1 — trailing inline kill-pane after claude exits
      local tmpscript
      tmpscript="$(mktemp /tmp/claude-tmux-cmd.XXXXXX.sh)"
      {
        printf '#!/bin/sh\n'
        printf 'command claude %s\n' "${(j: :)${(q-)_CLAUDE_TMUX_WATCH_ARGS}}"
        printf 'echo "$(date +%%s)" > %s\n' "$(printf %q "$stamp_path")"
        printf 'tmux kill-pane -t %s 2>/dev/null\n' "$watcher_pane"
        printf 'rm -f %s\n' "$(printf %q "$tmpscript")"
      } > "$tmpscript"
      chmod +x "$tmpscript"

      # Step 7: Respawn claude pane with the real command (replaces sleep infinity)
      tmux respawn-pane -k -t "$claude_pane" "$tmpscript"

      # Step 8: Attach
      tmux attach-session -t "$new_key"
    else
      # Existing behavior — use sanitized args (--watch/--no-watch already stripped)
      local claude_args=${(q-)_CLAUDE_TMUX_WATCH_ARGS}
      tmux new-session -s "$new_key" "command claude $claude_args; echo \$(date +%s) > \"$stamp_path\""
    fi
    echo $(date +%s) > "$stamp_path"
  else
    # Inside tmux: watcher split on current window
    _claude_tmux_parse_watch_flag "$@"
    local watcher_script; watcher_script="$(_claude_tmux_watch_script)"

    local watcher_active=0
    if _claude_tmux_watch_enabled \
       && _claude_tmux_version_ok \
       && [[ -x "$watcher_script" ]]; then
      watcher_active=1
    elif _claude_tmux_watch_enabled; then
      print -u2 "claude-tmux: watcher requested but unavailable; launching claude without watcher"
    fi

    if (( watcher_active )); then
      local claude_pane="$TMUX_PANE"
      local session
      session="$(tmux display-message -p '#{session_name}')"

      # Split right 30%, capture watcher pane id, pass --claude-pane (Layer 3)
      local watcher_pane
      watcher_pane="$(tmux split-window -h -p 30 -t "$claude_pane" -P -F '#{pane_id}' \
        "$watcher_script --cwd $(printf %q "$PWD") --claude-pane $claude_pane")"
      tmux select-pane -t "$claude_pane"

      # Layer 2: window-scope hook + #{hook_pane} guard + self-unregister
      _claude_tmux_attach_cleanup_hook "$session" "$claude_pane" "$watcher_pane"

      # Layer 1 (this branch): trap EXIT covers graceful exits
      trap "
        tmux kill-pane -t '$watcher_pane' 2>/dev/null
        tmux set-hook -wu -t '$session' pane-exited 2>/dev/null
      " EXIT INT TERM

      command claude "${_CLAUDE_TMUX_WATCH_ARGS[@]}"

      trap - EXIT INT TERM
      tmux kill-pane -t "$watcher_pane" 2>/dev/null
      tmux set-hook -wu -t "$session" pane-exited 2>/dev/null
    else
      command claude "$@"
    fi
  fi
}

claude() { _claude_tmux "$@" }
