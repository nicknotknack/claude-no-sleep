# no-sleep

![no-sleep](https://raw.githubusercontent.com/nicknotknack/claude-no-sleep/assets/banner.png)

Keep your Mac awake while a Claude Code session is running.

Useful for Remote Control: you start a session at your desk, walk away, and keep working from your phone. Without no-sleep the Mac falls asleep after a few minutes and the session drops.

```
/no-sleep
```

That's it. The Mac stays awake until you close this Claude Code session. When it ends, sleep works normally again.

## Install

```bash
claude plugin marketplace add nicknotknack/claude-no-sleep
claude plugin install no-sleep@no-sleep
```

Requirements: macOS. Nothing else to install: no-sleep uses `caffeinate`, which comes with macOS.

## Usage

| Command | What it does |
|---|---|
| `/no-sleep` | Keep the Mac awake until this session ends |
| `/no-sleep 2h` | Same, but stop after 2 hours at most. Also `30m`, `1h30m`, `45` (minutes) |
| `/no-sleep --display` | Also keep the screen on |
| `/no-sleep off` | Let the Mac sleep again |
| `/no-sleep off all` | Turn it off in every session |
| `/no-sleep status` | Show which sessions keep the Mac awake |

Running `/no-sleep` again in the same session replaces the previous setting, so `/no-sleep 1h` after `/no-sleep` just adds a time limit.

You can also ask in plain words: "don't let the Mac sleep while I'm away".

## Several sessions at once

Each terminal window with Claude Code gets its own lock. Turn on no-sleep in three windows and the Mac stays awake until the last of them closes or turns it off. `/no-sleep off` affects only the session you type it in.

```
$ /no-sleep status
- session 4084 (this session): until session ends, display may-sleep, ~/code/api
- session 5120: 1h12m left, display on, ~/code/web
Power: charger
```

## Good to know

- **The screen can turn off.** By default only the Mac itself stays awake; the display sleeps as usual, which is fine for Remote Control. Add `--display` if you need the screen on.
- **Closing the lid still puts the Mac to sleep.** This is a macOS rule that `caffeinate` can't override. Keep the lid open, or connect an external display, keyboard and charger (clamshell mode).
- **Use the charger.** On battery, macOS may still sleep. no-sleep warns you when the Mac runs on battery.
- **`/clear` keeps it on.** It's the same session. Only quitting Claude Code (or closing the terminal) ends it.

## How it works

All logic is in [`bin/no-sleep.sh`](bin/no-sleep.sh), a short Bash script. It makes no network requests and needs no admin rights.

1. Finds the process ID of the Claude Code session you typed the command in.
2. Starts `caffeinate -ims -w <that PID>` in the background (`-dims` with `--display`, plus `-t <seconds>` with a time limit).
3. `caffeinate` watches that process and exits on its own when the session ends. Nothing is left running.
4. Saves a small state file per session in `~/.claude/no-sleep/` so `status` and `off` know what's running.

Check it yourself any time:

```bash
pmset -g assertions | grep caffeinate
```

## Troubleshooting

**"could not find the Claude Code process".** no-sleep looks for a parent process named `claude`. Open an issue and include the output of `ps -o pid,ppid,comm -p $PPID`.

**The Mac slept anyway.** Check `/no-sleep status`, make sure the lid is open and the charger is connected.

## License

MIT
