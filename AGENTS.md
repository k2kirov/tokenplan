# Agent instructions

## Documentation

- Read `docs/index.json` first and filter by `kind` and `status`. Never grep `docs/` blind.
- Documents are grouped by authority: `product/` (committed scope), `engineering/` (how the code
  works now, including `adr/` and `runbooks/`), `plans/` (work in flight), `reference/` (captured
  from elsewhere, never a build spec), `archive/` (superseded).
- Create documents with `npx docs-notary new docs/<tier>/<name>.md --title "..." --summary "..."`
  and move them between tiers with `npx docs-notary mv`. Never hand-write frontmatter or edit
  `docs/INDEX.md` / `docs/index.json`; run `npm run gen:docs-index`.
- A `reference` document must be promoted (`docs-notary mv` into `product/` or `plans/`) before
  anything is built from it.
- Documents another tool writes under an unrecognised path get sorted into a tier before commit.
- When you change behaviour in `tokenplan`, update the matching document in
  `docs/engineering/` in the same change, then run `npm run lint:docs`.

## Code

- The tool is a single standard-library Python 3.11+ script, `tokenplan`. Keep it dependency-free.
- `package.json` exists only for the docs tooling.
