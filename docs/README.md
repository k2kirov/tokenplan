# Documentation

Documents are grouped by **authority** — how much weight a reader should give them — not by topic.

**Agents: read [`index.json`](index.json) first and filter by `kind` and `status`. Never grep
this tree blind.** [`INDEX.md`](INDEX.md) is the same data for humans. Both are generated — run
`gen:docs-index` after adding, moving or restatusing a document; never hand-edit them.

| Tier | `kind` | What it is |
|---|---|---|
| `reference/` | `reference` | Captured from elsewhere. **Not a commitment, never a build spec.** Promote before implementing. |
| `product/` | `product` | Committed scope. |
| `engineering/` | `engineering` | How this repository works. `engineering/adr/` and `engineering/runbooks/` have their own kinds. |
| `plans/` | `plan` | Work in flight. |
| `archive/` | `archive` | Replaced — every file here is `status: superseded` and names its replacement. |

Every `.md` here carries YAML frontmatter (`title`, `kind`, `status`, `updated`, and an
optional one-line `summary`); the `lint:docs` script is the blocking gate that keeps all of it
true.

Do not hand-write that block. `docs-notary new <path> --title "…" --summary "…"` writes a
document that passes the gate on its first run, and `docs-notary mv <from> <to>` moves one
between tiers — restamping `kind` and `status`, recording `promoted_from`. Both regenerate the
index.

This tree is managed by [docs-notary](https://github.com/magnifito/docs-notary).
