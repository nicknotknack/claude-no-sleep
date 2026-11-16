#!/bin/bash
# no-sleep: keep the Mac awake while a Claude Code session is running.
# Each session gets its own `caffeinate -w <claude pid>`, which exits on its own
# when that session ends, when the timer runs out, or on `off`.

set -u

STATE_DIR="${HOME}/.claude/no-sleep"
mkdir -p "$STATE_DIR"

die() { echo "error: $*" >&2; exit 1; }

[ "$(uname)" = "Darwin" ] || die "no-sleep works on macOS only (it uses caffeinate)."
command -v caffeinate >/dev/null || die "caffeinate not found."

alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }

# Walk up the process tree to the Claude Code process that owns this shell.
find_session_pid() {
  local p=$$ comm args
  while [ -n "$p" ] && [ "$p" -gt 1 ]; do
    comm=$(ps -o comm= -p "$p" 2>/dev/null) || break
    args=$(ps -o args= -p "$p" 2>/dev/null)
    case "$(basename "$comm")" in
      claude) echo "$p"; return ;;
    esac
    case "$args" in
      *"/claude "*|*"/claude"|*"claude-code"*|*"/cli.js"*) echo "$p"; return ;;
    esac
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
  return 1
}

# "2h", "30m", "1h30m", "45" (minutes) -> seconds
parse_duration() {
  local s="$1" h=0 m=0
  if [[ "$s" =~ ^([0-9]+)$ ]]; then m=${BASH_REMATCH[1]}
  elif [[ "$s" =~ ^([0-9]+)h([0-9]+)m?$ ]]; then h=${BASH_REMATCH[1]}; m=${BASH_REMATCH[2]}
  elif [[ "$s" =~ ^([0-9]+)h$ ]]; then h=${BASH_REMATCH[1]}
  elif [[ "$s" =~ ^([0-9]+)m(in)?$ ]]; then m=${BASH_REMATCH[1]}
  else return 1; fi
  local total=$(( h * 3600 + m * 60 ))
  [ "$total" -gt 0 ] || return 1
  echo "$total"
}

fmt_left() {
  local s=$1
  if [ "$s" -ge 3600 ]; then printf '%dh%02dm' $((s / 3600)) $((s % 3600 / 60))
  else printf '%dm' $(((s + 59) / 60)); fi
}

# State file per session: <session pid>.state
#   st_caf=<caffeinate pid> st_cwd=<dir> st_started=<epoch> st_until=<epoch|0> st_display=<0|1>
read_state() {
  st_caf="" st_cwd="" st_started=0 st_until=0 st_display=0
  # shellcheck disable=SC1090
  [ -f "$1" ] && . "$1"
}

stop_one() {
  local file="$1"
  read_state "$file"
  alive "$st_caf" && [ "$(ps -o comm= -p "$st_caf" 2>/dev/null)" = "/usr/bin/caffeinate" ] && kill "$st_caf" 2>/dev/null
  rm -f "$file"
}

cleanup_dead() {
  local f sid
  for f in "$STATE_DIR"/*.state; do
    [ -e "$f" ] || continue
    sid=$(basename "$f" .state)
    read_state "$f"
    if ! alive "$sid" || ! alive "$st_caf"; then rm -f "$f"; fi
  done
}

on_battery() { pmset -g batt 2>/dev/null | head -1 | grep -q "Battery Power"; }

cmd_on() {
  local dur="" display=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --for) shift; dur="${1:-}" ;;
      --display|-d) display=1 ;;
      *) dur="$1" ;;
    esac
    shift
  done

  local sid; sid=$(find_session_pid) || die "could not find the Claude Code process for this session."
  local secs=0
  if [ -n "$dur" ]; then secs=$(parse_duration "$dur") || die "bad duration '$dur'. Use 2h, 30m, 1h30m or minutes."; fi

  local file="$STATE_DIR/$sid.state"
  [ -f "$file" ] && stop_one "$file"

  local flags="-ims"
  [ "$display" = 1 ] && flags="-dims"
  local args=("$flags" -w "$sid")
  [ "$secs" -gt 0 ] && args+=(-t "$secs")

  nohup /usr/bin/caffeinate "${args[@]}" >/dev/null 2>&1 &
  local caf=$!
  disown "$caf" 2>/dev/null

  local now; now=$(date +%s)
  local until_ts=0; [ "$secs" -gt 0 ] && until_ts=$((now + secs))
  cat >"$file" <<EOF
st_caf=$caf
st_cwd='${PWD//\'/}'
st_started=$now
st_until=$until_ts
st_display=$display
EOF

  alive "$caf" || { rm -f "$file"; die "caffeinate failed to start."; }

  echo "ON"
  echo "session: $sid"
  if [ "$secs" -gt 0 ]; then echo "until: $(date -r "$until_ts" '+%H:%M') (in $(fmt_left "$secs")), or until the session ends"
  else echo "until: the session ends"; fi
  [ "$display" = 1 ] && echo "display: kept on" || echo "display: may turn off (the Mac stays awake)"
  on_battery && echo "WARNING: on battery. macOS can still sleep when the lid is closed; plug in the charger."
  return 0
}

cmd_off() {
  if [ "${1:-}" = "--all" ] || [ "${1:-}" = "all" ]; then
    local n=0 f
    for f in "$STATE_DIR"/*.state; do [ -e "$f" ] || continue; stop_one "$f"; n=$((n + 1)); done
    echo "OFF: stopped $n session(s)"
    return 0
  fi
  local sid; sid=$(find_session_pid) || die "could not find the Claude Code process for this session."
  local file="$STATE_DIR/$sid.state"
  if [ -f "$file" ]; then stop_one "$file"; echo "OFF: session $sid can sleep again"
  else echo "OFF: no-sleep was not active in this session"; fi
}

cmd_status() {
  cleanup_dead
  local me; me=$(find_session_pid 2>/dev/null || echo "")
  local now n=0 f sid left mark; now=$(date +%s)
  for f in "$STATE_DIR"/*.state; do
    [ -e "$f" ] || continue
    sid=$(basename "$f" .state)
    read_state "$f"
    left="until session ends"
    [ "$st_until" -gt 0 ] && left="$(fmt_left $((st_until - now))) left"
    mark=""; [ "$sid" = "$me" ] && mark=" (this session)"
    echo "- session $sid$mark: $left, display $([ "$st_display" = 1 ] && echo on || echo may-sleep), $st_cwd"
    n=$((n + 1))
  done
  [ "$n" -eq 0 ] && echo "No sessions are keeping the Mac awake."
  on_battery && echo "Power: battery" || echo "Power: charger"
  return 0
}

case "${1:-on}" in
  on) shift 2>/dev/null; cmd_on "$@" ;;
  off|stop) shift; cmd_off "$@" ;;
  status|list) cmd_status ;;
  *) cmd_on "$@" ;;
esac
