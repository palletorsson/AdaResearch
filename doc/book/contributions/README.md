# Spine contributions overlay

Editorial metadata for the contribution view at
`http://localhost:3003/map-curator?view=contributions&sequence=primitives&map=Point_One`.
Brief: [`doc/book/handoffs/claude-spine-contributions.md`](../handoffs/claude-spine-contributions.md).

The question this overlay helps answer is: **what can the visitor do with this artifact here, and
what does that make possible next?** It records proposals about that. It does not decide where
anything stands, what role it has, or what the book says.

## What lives here

| file | what | who writes it |
|---|---|---|
| `records.json` | subjects, artifact knowledge, contributions to halls, hall summaries. Each record keeps its prior versions in `history`. | `POST /api/contributions op=record.put` only |
| `reviews.jsonl` | append-only review events: proposed / accepted / deferred / rejected / comment, each with a reason and a declared reviewer | `POST /api/contributions op=review` only |
| `suggestions/<generator>.json` | generated hints, overwritten on every regeneration | `npx tsx scripts/contributions-suggest.ts --generator=<id>` (in the encyclopedia) |
| `export/primitives.sample.json` | a derived sample export (GET `op=export`); never read back | anyone, by curl |

Never hand-edit `records.json` or `reviews.jsonl`. A record's digest will stop verifying and every
later write to it is refused until it is restored from git.

## Rules

- **A claim is not a decision.** No record carries a review state. Review state is folded from
  `reviews.jsonl` every time a page is read.
- **Accepting a contribution accepts an editorial proposal.** It does not move an artifact, change
  its role, promote it to primary, or write `final.md`. Placement changes go through the Map
  Curator board and `/api/maps/cell-edit`.
- **Only a human reviewer on the allowlist may record a decision.** The allowlist lives in code
  (`ada_encyclopedia/src/lib/contributions/vocab.ts`), so it cannot be changed by editing data.
  Agents and generators may write records and post comments. Reviewer names are **declared, not
  authenticated**: the encyclopedia has no login. The page says "declared by".
- **A decision binds to one version.** Editing a record afterwards makes it `proposed` again and
  the page shows "accepted on rev 1; rev 2 unreviewed".
- **Evidence goes stale on its own.** Every evidence item stores a fingerprint of its source file
  and of the anchored passage, cell, pointer or pattern count. Each page read compares them with
  the files as they are now: `current`, `drifted` (file changed, the anchored part did not — amber,
  not green), `stale`, or `unverifiable`. A stale source does not erase an earlier decision; the
  decision is shown with "evidence changed since decision".
- **Suggestions are disposable.** Regenerating them rewrites only `suggestions/`. Decisions about a
  suggestion live in `reviews.jsonl` under the suggestion's deterministic id, so they survive.
  Adopting a suggestion creates a record marked `generated`; adoption is not acceptance.
- **Unknown is a value.** A field nobody has verified says `unknown`. It is never filled with a
  plausible guess.
- **Nothing here is authoritative about the collection.** The registry, the maps, the role file,
  briefs and prose remain the sources of truth; this overlay points into them with fingerprints.
