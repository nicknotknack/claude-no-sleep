---
name: no-sleep
description: Block sleep on Linux while this Claude Code session is running (uses systemd-inhibit), for example during a Remote Control session. Use when the user says no-sleep, don't let the computer sleep, or keep it awake.
argument-hint: "[off | status]"
allowed-tools: Bash(sh "${CLAUDE_PLUGIN_ROOT}/bin/no-sleep-linux.sh" *)
---

Request: $ARGUMENTS

1. Pick the command: empty or `on` → `on`; `off`/`stop` → `off`; `status` → `status`.
2. Run exactly one command:

   ```bash
   sh "${CLAUDE_PLUGIN_ROOT}/bin/no-sleep-linux.sh" <command>
   ```
3. If it fails, show the error and state that nothing changed.
4. Reply in the user's language in one short line: the computer stays awake until this session or its terminal tab closes; `/no-sleep off` to stop early.
