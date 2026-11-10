---
title: Window triggers and the tick
summary: "How the launchd tick starts 5h windows at configured times, chains them back to back, and raises notifications"
kind: engineering
status: active
updated: 2026-11-10
---

# Window triggers and the tick

A provider's 5h window starts with the first message after the previous one ends. Without help,
the window starts whenever the user first types, which can leave a gap when it ends at an awkward
time. tokenplan starts windows itself by sending a one-line prompt at configured times.

## The tick

`launchd` runs `tokenplan tick` every 900 seconds and once when the agent loads
(`StartInterval`, `RunAtLoad`). Each tick:

1. Fetches both providers and appends a history snapshot.
2. Refreshes an expired Codex sign-in if needed ([ADR 0002](adr/0002-never-write-codex-auth.md)).
3. Processes trigger slots for each provider that reports a 5h window.
4. Sends an over-budget notification at most once per provider per work day.
5. Sends a fetch-error notification at most once per provider every 6 hours.

## Trigger slots

`<provider>.trigger_times` lists local times. For each slot, the tick looks at the most recent
occurrence at or before now:

- If it is older than `general.trigger_grace_minutes` (default 120), it is ignored.
- If it already fired, it is ignored.
- If a window is active, the slot **stays pending** and the next tick checks again.
- Otherwise the trigger command runs, the slot is marked fired, and a notification reports the
  result. At most one trigger fires per provider per tick.

Keeping a slot pending while a window runs is what chains windows: if a window ends at 12:09 and
the 12:00 slot is still within grace, the 12:15 tick starts the next window. The same grace lets a
slot missed during sleep fire after wake; launchd runs a missed interval when the Mac wakes.

Fired-slot records older than three days are pruned from `state.json`.

## Trigger commands

Defaults:

```toml
[claude]
trigger_cmd = ["claude", "-p", "Reply with OK only.", "--model", "haiku"]

[codex]
trigger_cmd = ["codex", "exec", "--skip-git-repo-check", "-c", "model_reasoning_effort=\"low\"", "Reply with OK only."]
```

The command runs with:

- `PATH` prefixed with `~/.local/bin`, `/opt/homebrew/bin`, `/usr/local/bin`, because launchd's
  `PATH` is minimal. The binary is resolved against that `PATH`.
- `ANTHROPIC_BASE_URL` removed, so a local proxy cannot intercept the call.
- `CLAUDE_CODE_OAUTH_TOKEN` set from the Keychain item `tokenplan-claude-oauth` when it exists
  (Claude only, see [ADR 0001](adr/0001-long-lived-token-for-triggers.md)).
- Working directory `~/.local/state/tokenplan`, standard input closed, 180 s timeout.

Output and exit code go to `tick.log`.

## Cloud routine for the morning slot

launchd cannot fire while the Mac is off, and a Mac asleep past the grace period misses the
first slot. A claude.ai cloud routine covers that: it runs in Anthropic's cloud on a cron schedule,
on the same subscription, so its session starts the Claude 5h window.

The routine sends a one-word prompt to `claude-haiku-5-5` with no repository and no connectors.
Create it at <https://claude.ai/code/routines> or with Claude Code's `/schedule`. Cron
expressions are in UTC and the server adds a few minutes of jitter, so `0 5 * * *` runs at about
07:05 in Sofia in winter and 08:05 in summer.

Keep the local slot at the same time. If the routine already started a window, the tick sees it
and skips; if the routine failed, the local trigger covers it. Later slots stay local, because
only the tick can wait for a running window to end.

## Choosing times

Space trigger times 5 hours apart, starting a little before the work day. `pmset repeat
wakeorpoweron` can wake the Mac for the first one.

Codex plans without a 5h window (such as `prolite`) skip triggering automatically, and resume if
the plan reports one again.
