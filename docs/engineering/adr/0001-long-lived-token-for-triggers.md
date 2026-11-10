---
title: "ADR 0001: Long-lived Claude token for unattended triggers"
summary: "Window triggers authenticate with a claude setup-token token from the Keychain instead of the interactive sign-in"
kind: adr
status: active
updated: 2026-11-10
---

# ADR 0001: Long-lived Claude token for unattended triggers

## Context

Claude Code's interactive OAuth sign-in has a fixed lifetime; refreshing the access token does not
extend it. When it lapses, launchd triggers fail silently overnight. Claude Code offers
`claude setup-token`, which issues a long-lived token meant for unattended jobs, read from
`CLAUDE_CODE_OAUTH_TOKEN`.

## Decision

`tokenplan set-token` reads the token with hidden input and stores it in the login Keychain as
generic password `tokenplan-claude-oauth`. `run_trigger` reads it for every Claude trigger and
passes it as `CLAUDE_CODE_OAUTH_TOKEN`. Without the item, triggers fall back to the normal
sign-in.

## Consequences

- Triggers keep working after the interactive sign-in expires.
- The token never sits in a file, the config, shell history or the process list of the shell.
- Usage **reading** still uses the interactive sign-in; the setup token is only proven to work for
  inference, which is all a trigger needs. The user must still renew that sign-in; see
  [the runbook](../runbooks/auth-renewal.md).

## Rejected

- **Token in `config.toml`:** plain-text secret in a file users may copy or commit.
- **Environment variable in the launchd plist:** same problem, and the plist is world-readable.
