---
title: Renewing sign-ins
summary: "Steps to restore usage reading and window triggers when a Claude or Codex sign-in expires"
kind: runbook
status: active
updated: 2026-11-10
---

# Renewing sign-ins

tokenplan depends on three credentials. A notification (`<provider> usage unavailable: HTTP 401`)
or an error line in `tokenplan` output usually means one has expired.

| Credential | Used for | Lifetime | Renew with |
|---|---|---|---|
| Claude Code sign-in (Keychain `Claude Code-credentials`) | Reading Claude usage | Fixed; Claude Code warns a few days ahead | `claude auth login` |
| Claude setup token (Keychain `tokenplan-claude-oauth`) | Claude window triggers | Long-lived | `claude setup-token`, then `tokenplan set-token` |
| Codex sign-in (`~/.codex/auth.json`) | Reading Codex usage | Access token ~10 days, refreshed on use | Automatic; otherwise run `codex` once |

## Claude usage shows an error

1. In a terminal, run the real binary (not a shell wrapper that routes through a proxy):
   ```sh
   ~/.local/bin/claude auth login
   ```
2. Check: `tokenplan` shows a CLAUDE block without an error.

## Claude triggers fail

`tick.log` shows `trigger claude rc=1` with an authentication error.

1. In a separate terminal (the token is printed, keep it out of shared transcripts):
   ```sh
   ~/.local/bin/claude setup-token
   tokenplan set-token     # paste the sk-ant-... token; input is hidden
   ```
2. Check: `tokenplan trigger claude`. If a window is active it says so and does nothing; otherwise
   `tick.log` gets `trigger claude rc=0 out='OK'`.

## Codex usage shows an error

The next tick runs Codex once to refresh it. If the error persists for more than one tick:

1. Run `codex` interactively once. If it asks you to sign in, run `codex login`.
2. Check: `tokenplan` shows a CODEX block without an error.
