![no-sleep](https://raw.githubusercontent.com/nicknotknack/claude-no-sleep/assets/banner.png)

# no-sleep for Linux

Keep your computer awake while a Claude Code session is running. Handy for Remote Control (`/rc`): start a session, walk away, keep working from your phone.

## Install

```bash
claude plugin marketplace add https://github.com/nicknotknack/claude-no-sleep.git#linux
claude plugin install no-sleep@no-sleep-linux
```

Requires a systemd-based distro (Ubuntu, Debian, Fedora, Arch…). Uses the built-in `systemd-inhibit`.

## Usage

| Command | What it does |
|---|---|
| `/no-sleep` | No sleep until this Claude session or its terminal tab closes |
| `/no-sleep off` | Allow sleep again |
| `/no-sleep status` | Show active locks |

## 💡 Good to know

- The lock is released automatically when the session ends. Nothing keeps running.
- Closing a laptop lid may still suspend it, depending on your desktop settings.
- Check it yourself: `systemd-inhibit --list | grep no-sleep`.

macOS version: [`main`](https://github.com/nicknotknack/claude-no-sleep) · Windows: [`windows`](https://github.com/nicknotknack/claude-no-sleep/tree/windows)
