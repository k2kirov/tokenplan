---
title: Product scope
summary: "What tokenplan does for the user, what it deliberately does not do, and the platforms it supports"
kind: product
status: shipped
code: tokenplan
updated: 2026-11-10
---

# Product scope

tokenplan helps one person on paid Claude and Codex subscriptions use as much of their weekly
allowance as possible without running out before the weekly reset.

## Committed behaviour

| Capability | Command / surface |
|---|---|
| Live usage for Claude (5h window + weekly) and Codex (weekly, plus 5h when the plan has one) | `tokenplan` |
| Today's budget, spent today, left today | `tokenplan` |
| Pace against an even spread over work hours (banked or behind) | `tokenplan` |
| How much more can be spent today ("stretch") and what that costs later days | `tokenplan` |
| Tomorrow's budget on plan, and if the user stops now ("carry") | `tokenplan` |
| One-line, colour-coded summary for status bars | `tokenplan line [--color]` |
| Machine-readable output | `tokenplan json` |
| Automatic start of a 5h window at configured times, chained back to back | launchd agent, `tokenplan tick` |
| Manual window start | `tokenplan trigger [claude\|codex]` |
| macOS notification when today's spend passes its budget | launchd agent |
| macOS notification when usage cannot be read (sign-in problems) | launchd agent |
| Agent skill so Claude Code and Codex can answer "how much can I spend?" | `skill/SKILL.md` |

## Units

Every number is a **percentage of the weekly limit**. Neither provider exposes token counts for
subscription plans, so tokenplan never claims to.

## Out of scope

- Token counts or dollar costs per request.
- API-key (pay-as-you-go) billing.
- Linux and Windows. tokenplan depends on the macOS Keychain, launchd and `osascript`.
- Multiple accounts per provider.
- Spending usage on the user's behalf beyond the one-line prompt that starts a window
  (and the Codex token refresh, see [ADR 0002](../engineering/adr/0002-never-write-codex-auth.md)).

## Requirements

- macOS, Python 3.11+ (for `tomllib`).
- Claude Code signed in with a Pro or Max subscription, and/or the Codex CLI signed in with ChatGPT.
