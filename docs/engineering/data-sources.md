---
title: Data sources
summary: "The two undocumented usage endpoints tokenplan reads, how it authenticates to each, and how they fail"
kind: engineering
status: active
updated: 2026-11-10
---

# Data sources

Both endpoints are undocumented and used by the official clients. Either can change shape or
disappear without notice. tokenplan reads them only; it never calls anything that spends usage,
except the window trigger (see [triggers](triggers.md)).

## Claude

| | |
|---|---|
| Endpoint | `GET https://api.anthropic.com/api/oauth/usage` |
| Headers | `Authorization: Bearer <accessToken>`, `anthropic-beta: oauth-2025-04-20` |
| Credential | Keychain item `Claude Code-credentials`, field `claudeAiOauth.accessToken` (Claude Code's own sign-in) |
| Fields used | `five_hour.utilization`, `five_hour.resets_at`, `seven_day.utilization`, `seven_day.resets_at`; plan name from `claudeAiOauth.rateLimitTier` |

`five_hour.resets_at` stays set after a window ends. tokenplan treats a window as active only
while `resets_at` is in the future.

The long-lived token from `claude setup-token` is **not** used here; tokenplan only passes it to
window triggers. Usage reading depends on the normal Claude Code sign-in staying valid. See
[the auth runbook](runbooks/auth-renewal.md).

## Codex

| | |
|---|---|
| Endpoint | `GET https://chatgpt.com/backend-api/wham/usage` |
| Headers | `Authorization: Bearer <access_token>`, `ChatGPT-Account-Id: <account_id>` |
| Credential | `~/.codex/auth.json`, `tokens.access_token` and `tokens.account_id` |
| Fields used | `plan_type`; `rate_limit.primary_window` and `secondary_window` (`used_percent`, `limit_window_seconds`, `reset_at`); `credits.balance` |

Windows are classified by length, not position: a window of 6 days or more is the weekly limit,
6 hours or less is the 5h window. Plans have changed which slot holds which (Plus had a 5h primary
and weekly secondary; `prolite` has only a weekly primary), so position is not reliable.

## Failure modes

| Symptom | Cause | Handling |
|---|---|---|
| Claude `HTTP 401` | Claude Code sign-in expired | Notification with the fix; see [runbook](runbooks/auth-renewal.md) |
| Codex `HTTP 401` | Access token expired (about 10 days after refresh) | `tick` runs Codex once so it refreshes itself ([ADR 0002](adr/0002-never-write-codex-auth.md)) |
| `no Claude Code credentials in keychain` | Claude Code never signed in on this Mac | Provider shown as error; the other still works |
| `no weekly window reported` | Codex response shape changed | Provider shown as error |

A failing provider never blocks the other.
