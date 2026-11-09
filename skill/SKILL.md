---
name: tokenplan
description: Show how to pace Claude and Codex subscription usage until the weekly reset - today's budget, banked surplus, how much more can be spent today, what carries to tomorrow, 5h window state and next auto-trigger. Use when the user asks about token budget, usage limits, how much they can spend, pacing, weekly reset, or 5h windows.
---

Run `~/.local/bin/tokenplan` and relay the result. All numbers are % of the weekly limit
(providers expose usage only as percentages).

How to read it:
- `pace`: positive = banked surplus versus an even spread over work hours.
- `today budget/left`: even share of what remains, spread over remaining work hours.
- `stretch`: the most that can be spent today while later days keep `min_future_day_share` of an even day.
- `carry`: tomorrow's budget on plan versus if the user stops now.
- `5h win`: current window; `spend <= X%` is the suggested weekly spend inside this window.

Other commands: `tokenplan line` (one line), `tokenplan json`, `tokenplan trigger [claude|codex]`
(start a 5h window now), `tokenplan config` (config at ~/.config/tokenplan/config.toml: work hours,
reserve, trigger times). A launchd agent (`com.tokenplan.tick`) runs `tokenplan tick` every 15 min:
snapshots usage, starts 5h windows at the configured trigger times when idle, and notifies when
today's spend passes budget. Logs: ~/.local/state/tokenplan/tick.log.

Give a short recommendation: which provider to lean on now (the one with more banked surplus
or a fresh 5h window), and whether the user can afford a heavy session today.
