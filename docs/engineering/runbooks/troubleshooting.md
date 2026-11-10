---
title: Troubleshooting
summary: "Diagnosing a missing status line, triggers that do not fire, wrong times and launchd problems"
kind: runbook
status: active
updated: 2026-11-10
---

# Troubleshooting

## Where to look

| What | Where |
|---|---|
| Trigger results, fetch errors | `~/.local/state/tokenplan/tick.log` |
| launchd stdout / stderr (Python crashes) | `~/.local/state/tokenplan/launchd.out`, `launchd.err` |
| Fired slots, warnings sent | `~/.local/state/tokenplan/state.json` |
| Snapshots | `~/.local/state/tokenplan/history.jsonl` |

## The launchd agent is not running

```sh
launchctl list | grep tokenplan        # expect: -  0  com.tokenplan.tick
tokenplan install                      # reload it
```

A non-zero middle column is the last exit status; read `launchd.err`.

## A trigger did not fire

- **A window was active the whole grace period.** Expected; no log line is written for a
  pending slot.
- **The Mac was asleep longer than `trigger_grace_minutes`.** Expected. Increase the grace or
  schedule a wake with `pmset`.
- **The provider has no 5h window.** `tokenplan` shows `5h win none on this plan`.
- **`not found in PATH`** in `tick.log`: set an absolute path in `trigger_cmd`.
- **`rc=1`** with an auth error: see [renewing sign-ins](auth-renewal.md).

## Times are off by hours

tokenplan uses the system time zone from `/etc/localtime`, not `TZ`. Check
`readlink /etc/localtime`. Weekly reset times are shown in that zone.

## "spent today unknown"

No snapshot exists at or before the start of the work day. It resolves itself once the tick has
run across a `day_start`.

## The status line is blank

The Claude Code status line shows a cached copy refreshed in the background at most once a
minute. The first render after the cache is cleared is blank. Run `tokenplan line --color` directly
to see errors.

## Reset everything

```sh
./uninstall.sh                           # keeps config and history
rm -rf ~/.local/state/tokenplan          # drop history and state
./install.sh
```
