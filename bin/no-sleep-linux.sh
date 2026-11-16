#!/bin/sh
# no-sleep (Linux): block sleep while this Claude Code session is running.
# Uses systemd-inhibit; the lock is released when the session (or its terminal tab) closes.

STATE_DIR="$HOME/.claude/no-sleep"
mkdir -p "$STATE_DIR"

die() { echo "error: $*" >&2; exit 1; }

command -v systemd-inhibit >/dev/null || die "systemd-inhibit not found (needs a systemd-based distro)."

# Walk up to the Claude Code process; fall back to the terminal shell.
session_pid() {
  p=$$
  while [ -n "$p" ] && [ "$p" -gt 1 ]; do
    args=$(ps -o args= -p "$p" 2>/dev/null) || break
    case "$(ps -o comm= -p "$p")" in claude) echo "$p"; return ;; esac
    case "$args" in *"/claude "*|*"/claude"|*claude-code*) echo "$p"; return ;; esac
    p=$(ps -o ppid= -p "$p" | tr -d ' ')
  done
  echo "$PPID"
}

SID=$(session_pid)
FILE="$STATE_DIR/$SID.pid"

stop() {
  if [ -f "$FILE" ]; then
    pid=$(cat "$FILE")
    pkill -P "$pid" 2>/dev/null
    kill "$pid" 2>/dev/null
  fi
  rm -f "$FILE"
}

case "${1:-on}" in
  on)
    stop
    setsid nohup systemd-inhibit --what=sleep:idle --who=no-sleep \
      --why="Claude Code session $SID" --mode=block \
      sh -c 'while kill -0 "$1" 2>/dev/null; do sleep 5; done' _ "$SID" \
      >/dev/null 2>&1 &
    echo $! >"$FILE"
    sleep 1
    kill -0 "$(cat "$FILE")" 2>/dev/null || { rm -f "$FILE"; die "systemd-inhibit failed to start."; }
    echo "ON: no sleep until session $SID ends" ;;
  off)
    stop
    echo "OFF: sleep allowed again" ;;
  status)
    systemd-inhibit --list 2>/dev/null | grep no-sleep || echo "No sessions are blocking sleep." ;;
  *) die "usage: no-sleep-linux.sh [on|off|status]" ;;
esac
