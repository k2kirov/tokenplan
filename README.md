# tokenplan

Pace your **Claude** and **Codex** subscription usage so it lasts until the weekly reset, and gets used up by then.

`tokenplan` reads live usage from both providers and works out:

- **today's budget**: what's left of the week, spread evenly over the work hours remaining before the reset
- **pace**: whether you are ahead (banked) or behind compared with an even spread
- **stretch**: the most you can spend today while later days keep a minimum share
- **carry**: tomorrow's budget if you stay on plan, and if you stop now
- **5h window**: current window usage, its reset time, and a suggested spend inside it

It also **starts 5-hour windows automatically** at set times by sending a tiny prompt, so windows run back to back through your work day instead of starting whenever you first type.

```
CLAUDE  [default_claude_max_5x]
  week    [#########...............] 36% used, 61% spendable (reserve 3%)
  reset   Thu 08:00 (in 2.7d)  |  43.3 work hours left
  pace    should be at 62%, you are 25.7% ahead (banked)
  today   budget 13.1%  spent 0.4%  left 12.7%
  rate    1.41%/work hour
  stretch can spend up to 37.1% more today (later days drop to 12.0%/day)
  carry   tomorrow on plan 23.9%  |  stop now: 30.5%
  5h win  [##......................] 8% used, resets 21:30 (in 3h48m)  | spend <= 13.1% weekly here
  trigger next auto-start 22:00 (in 4h18m)
```

All numbers are **% of the weekly limit**. Both providers report usage only as percentages, not token counts.

## Requirements

- macOS (uses the Keychain and launchd)
- Python 3.11+
- Claude Code signed in with a Pro/Max subscription, and/or the Codex CLI signed in with ChatGPT

## Install

```sh
git clone https://github.com/k2kirov/tokenplan.git ~/dev/tokenplan
~/dev/tokenplan/install.sh
```

The installer:

1. symlinks `tokenplan` into `~/.local/bin` (set `BIN_DIR` to change)
2. installs the `tokenplan` skill into `~/.claude/skills` and `~/.codex/skills`, so you can ask either agent "how much can I spend today?"
3. loads a launchd agent (`com.tokenplan.tick`) that runs every 15 minutes
4. writes the default config to `~/.config/tokenplan/config.toml`

Remove everything with `./uninstall.sh`. Your config and history are kept.

## Usage

```sh
tokenplan                    # full report
tokenplan line [--color]     # one line, for status bars
tokenplan json               # machine-readable
tokenplan trigger [claude|codex]   # start a 5h window now (skipped if one is active)
tokenplan config             # show config path and contents
tokenplan set-token          # store a `claude setup-token` token for unattended triggers
tokenplan install|uninstall  # manage the launchd agent
```

### Status line

Claude Code `statusLine` command or tmux:

```sh
tokenplan line --color
# Claude 🟢 23% left today ▲30 ⏳20%→12:09  │  Codex 🟢 35% left today ▲28
```

- 🟢 / 🟡 / 🔴: today's budget is on track / over 80% used / exceeded
- `23% left today`: % of the weekly limit still in today's budget
- ▲30 (green) / ▼5 (red): % ahead of / behind an even weekly pace
- ⏳20%→12:09: current 5h window usage (green/yellow/red at 70/90%) and its reset time

Drop `--color` for plain text.

It makes two network calls, so cache it if your status line refreshes often.

## Configuration

`~/.config/tokenplan/config.toml`:

```toml
[general]
day_start = "08:00"          # work hours; budgets are spread over these only
day_end = "01:00"            # earlier than day_start = crosses midnight
reserve_pct = 3              # % of the week kept untouched as a safety margin
min_future_day_share = 0.5   # when stretching, later days keep >= 50% of an even day
notify_over_budget = true    # macOS notification when today's spend passes the budget
trigger_grace_minutes = 120  # how long a trigger slot waits for a running window to end / the Mac to wake

[claude]
enabled = true
trigger_times = ["07:00", "12:00", "17:00", "22:00"]
trigger_cmd = ["claude", "-p", "Reply with OK only.", "--model", "haiku"]

[codex]
enabled = true
trigger_times = ["07:00", "12:00", "17:00", "22:00"]
trigger_cmd = ["codex", "exec", "--skip-git-repo-check", "-c", "model_reasoning_effort=\"low\"", "Reply with OK only."]
```

**Choosing trigger times:** space them 5 hours apart and start the first one a little before you begin work. Your first window is then already running when you sit down, and a fresh one is ready when it runs out. If a window is still running at a trigger time, the trigger waits and fires on the first tick after the window ends, so windows run back to back. A trigger missed while the Mac was asleep fires on wake. Both are limited by `trigger_grace_minutes` (default 120).

To have the Mac awake for the first trigger, schedule a daily wake a few minutes before it:

```sh
sudo pmset repeat wakeorpoweron MTWRFSU 06:55:00
```

## How it works

| | Source |
|---|---|
| Claude | `GET https://api.anthropic.com/api/oauth/usage`, using the Claude Code OAuth token from the macOS Keychain (`Claude Code-credentials`) |
| Codex | `GET https://chatgpt.com/backend-api/wham/usage`, using the token in `~/.codex/auth.json` |

Both are undocumented endpoints used by the official clients and may change without notice.

Every tick appends a snapshot to `~/.local/state/tokenplan/history.jsonl`. Snapshots let tokenplan:

- work out **spent today** (the difference from the first snapshot of the work day)
- learn **how much of the week one full 5h window costs**, once enough data exists

Trigger runs and errors are logged to `~/.local/state/tokenplan/tick.log`.

### Budget math

- `remaining = 100 - reserve - used`
- `rate = remaining / work hours until reset`
- `today = rate × work hours left today`
- `stretch = remaining - min_future_day_share × rate × work hours after today`
- `pace = (100 - reserve) × elapsed work hours / total work hours this week - used`

Unspent budget is automatically spread over the remaining days, because the rate is recomputed from what is left.

## Notes

- **Unattended triggers need a long-lived Claude token.** OAuth sign-ins expire. Run `claude setup-token`, then `tokenplan set-token` and paste the token (input hidden). It is stored in the Keychain as `tokenplan-claude-oauth` and passed to the trigger as `CLAUDE_CODE_OAUTH_TOKEN`. Usage reading still uses your normal Claude Code sign-in.
- **Sign-in problems are reported.** If usage can't be read, you get a macOS notification (at most every 6 hours) saying what to do. For Claude, run `claude auth login` before the sign-in expires.
- **Codex refreshes itself.** When the Codex token expires, tokenplan runs one tiny `codex exec` (about 25k tokens, at most every 6 hours) so the official client refreshes its own sign-in. tokenplan never writes `~/.codex/auth.json`.
- Codex plans without a 5h window (weekly only) skip triggering automatically, and it turns back on if the plan reports one.
- `ANTHROPIC_BASE_URL` is removed from the trigger environment so local proxies don't intercept the call.
- The shell's `TZ` is ignored. Times use the macOS system time zone.

## Documentation

Design, budget formulas, data sources, decisions and runbooks live in [`docs/`](docs/README.md).
Agents: start from [`docs/index.json`](docs/index.json).

## License

MIT
