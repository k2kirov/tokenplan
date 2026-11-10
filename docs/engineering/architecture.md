---
title: Architecture
summary: "Components, data flow and on-disk files of tokenplan"
kind: engineering
status: active
updated: 2026-11-10
---

# Architecture

tokenplan is one standard-library Python script (`tokenplan`) plus a launchd agent and an agent
skill. There is no daemon of its own and no database: state is a few small files.

## Components

| Component | Where | Role |
|---|---|---|
| CLI | `tokenplan` (symlinked to `~/.local/bin/tokenplan` by `install.sh`) | Fetch, plan, report, trigger |
| launchd agent | `~/Library/LaunchAgents/com.tokenplan.tick.plist` | Runs `tokenplan tick` every 15 minutes and at load |
| Agent skill | `skill/SKILL.md`, symlinked into `~/.claude/skills/tokenplan/` and `~/.codex/skills/tokenplan/` | Lets either agent run tokenplan and explain the result |
| Config | `~/.config/tokenplan/config.toml` | Work hours, reserve, trigger times and commands. Written with defaults on first run; user values are merged over the defaults per key |
| History | `~/.local/state/tokenplan/history.jsonl` | One usage snapshot per provider per tick |
| State | `~/.local/state/tokenplan/state.json` | Which trigger slots fired, which warnings were sent, last Codex heal |
| Log | `~/.local/state/tokenplan/tick.log` | Trigger results and fetch errors |

## Data flow

```
fetch_claude / fetch_codex      live usage from the providers (see data-sources.md)
        │
        ▼
append_history (tick only, or first run of a work day)
        │
        ▼
plan()                          budget model (see budget-model.md)
        │
        ├── report()            tokenplan / tokenplan status
        ├── one_line()          tokenplan line [--color]
        ├── json                tokenplan json
        └── cmd_tick()          triggers, notifications (see triggers.md)
```

The interactive commands record a snapshot only when none exists yet for the current work day,
so "spent today" works even before the launchd agent has run. `tick` records on every run.

## Time

All times are in the macOS system time zone, read from `/etc/localtime`. The `TZ` environment
variable is ignored on purpose: a shell with `TZ=UTC` would otherwise shift every work-hour
boundary and trigger slot.

## Related documents

- [Data sources](data-sources.md)
- [Budget model](budget-model.md)
- [Window triggers and the tick](triggers.md)
