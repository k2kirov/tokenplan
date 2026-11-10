---
title: "ADR 0002: Never write the Codex auth file"
summary: "On an expired Codex token tokenplan runs Codex once to refresh itself instead of refreshing the token directly"
kind: adr
status: active
updated: 2026-11-10
---

# ADR 0002: Never write the Codex auth file

## Context

The Codex access token in `~/.codex/auth.json` lasts about 10 days. Codex refreshes it only when
it is used, so a user who doesn't open Codex for a while gets `HTTP 401` from the usage endpoint.

Refreshing directly against the OAuth token endpoint is possible, but refresh tokens rotate: the
old one is invalidated when a new one is issued. If tokenplan wrote `auth.json` while Codex was
also refreshing, or the write failed halfway, Codex would be signed out.

## Decision

tokenplan only ever reads `auth.json`. When a tick sees a Codex `HTTP 401`, it runs the Codex
trigger command once (at most every 6 hours), letting the official client refresh its own sign-in,
then fetches usage again.

## Consequences

- No risk of corrupting or racing the Codex sign-in.
- Each heal costs one small Codex request. Codex sends its full system prompt even for a one-word
  reply, measured at about 25k tokens, roughly once every 10 days.
- If the refresh token itself has expired, the heal fails and the user gets a notification to run
  `codex` interactively.
