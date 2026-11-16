![no-sleep](https://raw.githubusercontent.com/nicknotknack/claude-no-sleep/assets/banner.png)

# no-sleep for Windows

Keep your PC awake while a Claude Code session is running. Handy for Remote Control (`/rc`): start a session, walk away, keep working from your phone.

## Install

```bash
claude plugin marketplace add https://github.com/nicknotknack/claude-no-sleep.git#windows
claude plugin install no-sleep@no-sleep-windows
```

Requires Windows 10/11. Uses built-in PowerShell, nothing else to install.

## Usage

| Command | What it does |
|---|---|
| `/no-sleep` | No sleep until this Claude session or its terminal tab closes |
| `/no-sleep off` | Allow sleep again |
| `/no-sleep status` | Show active sessions |

## 💡 Good to know

- The lock is released automatically when the session ends. Nothing keeps running.
- The screen can still turn off; the PC itself stays awake.
- Closing a laptop lid follows your Windows lid settings and may still put it to sleep.
- Check it yourself: `powercfg /requests` (run as administrator).

macOS version: [`main`](https://github.com/nicknotknack/claude-no-sleep) · Linux: [`linux`](https://github.com/nicknotknack/claude-no-sleep/tree/linux)
