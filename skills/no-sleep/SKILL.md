---
name: no-sleep
description: Keep the Mac awake while this Claude Code session is running (uses caffeinate), for example during a Remote Control session. Turn it off or show which sessions keep the Mac awake. Use when the user says no-sleep, don't let the computer sleep, keep the Mac awake, or stay awake.
argument-hint: "[2h | 30m | 1h30m] [--display] | off [all] | status"
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/bin/no-sleep.sh" *)
---

Request: $ARGUMENTS

1. Pick the command from the request:
   - empty, `on`, a duration (`2h`, `30m`, `1h30m`, `45` = minutes) and/or `--display`: `on [duration] [--display]`
   - `off`, `stop`: `off`; `off all`: `off --all`
   - `status`, `list`: `status`
2. Run exactly one command:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/bin/no-sleep.sh" <command> [args]
   ```
3. If it fails, show the error and state that nothing changed.
4. Reply in the user's language in 1-3 short lines:
   - `on`: the Mac stays awake until this session ends (or until the time shown); `/no-sleep off` to stop early. If the output has `WARNING`, repeat it.
   - `off`: the Mac can sleep again.
   - `status`: the list of sessions as printed.
