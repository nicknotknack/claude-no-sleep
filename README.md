![no-sleep](https://raw.githubusercontent.com/nicknotknack/claude-no-sleep/assets/banner.png)

Keep your Mac awake while a Claude Code session is running.

Useful for Remote Control: you start a session at your desk, ```/rc```,  walk away, and keep working from your phone. Without ```/no-sleep``` the Mac falls asleep after a few minutes and the session drops.

## Install

```bash
claude plugin marketplace add nicknotknack/claude-no-sleep
claude plugin install no-sleep@no-sleep
```

works on macOS using `caffeinate`. On Windows or Linux? Use the [`windows`](https://github.com/nicknotknack/claude-no-sleep/tree/windows) or [`linux`](https://github.com/nicknotknack/claude-no-sleep/tree/linux) version.

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

## 💡 Good to know

- **The screen can turn off.** By default only the Mac itself stays awake; the display sleeps as usual, which is fine for Remote Control. Add `--display` if you need the screen on.
- **Closing the lid still puts the Mac to sleep.** This is a macOS rule that `caffeinate` can't override. Keep the lid open, or connect an external display, keyboard and charger (clamshell mode).
- **Use the charger.** On battery, macOS may still sleep. no-sleep warns you when the Mac runs on battery.
