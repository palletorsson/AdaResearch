# Proposal — the proposal chip + the pause primitive

_Drafted 2026-05-13, after [The hold collapsed](/blog/2026-05-13-the-hold-collapsed)_

This is a proposal, not an implementation. Per the failure mode the blog named, I am stopping here to surface the plan before building anything. **The implementation should not start until Palle has signed off on the four design choices marked DECISION below.**

## Goal

Make the *propose, hold, return* mechanism enforced by tooling, not just by discipline. Two pieces:

1. **The proposal chip** — sieve docs surface their structural recommendations in the encyclopedia as individual chips, each with apply / defer buttons. One chip per structural move. The chain cannot run as a single batch.
2. **The pause primitive** — when a session has produced proposals but not yet applied them, an explicit pause point holds the session and requires acknowledgement of each move before continuing.

The chamber pattern (`/api/chamber`, `/chamber`) is the structural ancestor. The chip + pause is the same idea applied one level up — at the *sieve-pass* level rather than the artifact level.

## Architecture

```
   doc/sieve_passes/*.md
   └── "Reorder candidates" tables  ─────┐
                                         │
   tools/sieve_proposals.py              │
   (parser: md → JSON)                   │
   └── data/sieve_proposals/             │
       {pass_id}_proposals.json  ◄──────┘
                                  │
   /api/sieve-proposals  ◄────────┘
   /sieve-proposals page (UI chips)
                                  │
   tools/apply_sieve_move.py  ◄───┘
   (applies one move on click)
```

### Component 1: parser (`tools/sieve_proposals.py`)

Scans `doc/sieve_passes/*.md` for the markdown table headed *"Reorder candidates"* (the format already used in tonight's sieves). Each row becomes one proposal record:

```json
{
  "pass_id": "2026-05-13T10-55-00_macro-qfep-arc",
  "move_id": "macro-1",
  "change": "cellularautomata",
  "from": "order 9, phase E_entropy",
  "to": "order 9, phase λ_edge",
  "impact": "medium — opens λ_edge with CA's universality",
  "rationale_excerpt": "(120 words from the sieve doc around this move)",
  "status": "pending",  // pending | applied | deferred | rejected
  "applied_at": null,
  "applied_by": null
}
```

Records persist in `data/sieve_proposals/{pass_id}_proposals.json`. The parser is idempotent — running it again updates rows whose status is `pending`, leaves `applied`/`deferred`/`rejected` alone.

### Component 2: API (`/api/sieve-proposals`)

```
GET  /api/sieve-proposals               → all proposals across all passes, grouped
GET  /api/sieve-proposals?pass=<id>     → one pass's proposals
POST /api/sieve-proposals/{id}/apply    → calls tools/apply_sieve_move.py, marks applied
POST /api/sieve-proposals/{id}/defer    → marks deferred
POST /api/sieve-proposals/{id}/reject   → marks rejected
```

### Component 3: UI page (`/sieve-proposals`)

Each pending proposal renders as a chip:

```
┌─────────────────────────────────────────────────┐
│ cellularautomata                  [medium]      │
│ order 9, phase E_entropy → order 9, phase λ_edge│
│                                                 │
│ "CA's truth (Rule 110 is Turing complete) is    │
│  the λ_edge claim's clearest statement."        │
│                                                 │
│ [Apply]  [Defer]  [Reject]   from: macro-qfep   │
└─────────────────────────────────────────────────┘
```

Applied chips collapse to a single-line summary. Rejected chips show why. Deferred chips remain visible.

### Component 4: pause primitive

This is the harder piece. Two paths:

**Path A — file-based.** A tool like `tools/pause_for_review.py --reason "7 structural moves pending"` writes to `ada_run/pause_holds.md`. The next session firing of `/loop` reads this file before continuing and refuses to proceed if any holds are unresolved. Palle clears the hold by visiting `/sieve-proposals` and resolving each chip; the tool detects all proposals in the relevant pass are non-pending and lifts the hold.

**Path B — skill-level.** Modify the `/loop` skill to detect "proposals pending" condition and itself refuse to run the next batch step until cleared.

DECISION 1: which path? Path A is more general (any session can declare a hold), more independent of skill internals, and matches the existing `ada_run/` feedback bridge pattern. Path B is more tightly coupled but requires no new file convention.

**Recommendation: Path A.** Keeps the substrate separable from any particular skill.

### Component 5: the apply script (`tools/apply_sieve_move.py`)

Translates a proposal record into a concrete JSON edit. This is the dangerous one — it modifies version-controlled files. Two safety properties:

1. **Reversible** — every apply writes a backup of the affected file under `data/sieve_proposals/backups/{pass_id}/{move_id}.json` first.
2. **Specific** — the script handles only the move types we see in practice: phase change, order change, layer change, unlock-edge edit, phase-truth insertion, new-phase insertion. Anything else returns "manual move — apply by hand."

DECISION 2: which move types to support in v1? Recommendation: phase + order + layer + unlock-edge, deferring phase-truth and new-phase insertions to manual edits. The latter two are rare and write multi-line content; cheaper to leave them as human-driven.

## Test sieve cycle

A small sieve to exercise the new substrate end-to-end:

**Target:** `doc/sieve_passes/` itself. Apply the three-question sieve to the sieve-pass document conventions.

Specifically, ask:
- Q1: Does the current sieve-pass format (markdown with "Reorder candidates" tables) thicken the cognitive water — i.e., make sieve work *reusable* across sessions?
- Q2: What does the format foreclose? Are there sieve moves that don't fit a table row and therefore get under-reported?
- Q3: What lives in the dark spot of the sieve-pass tradition we've built?

The pass should produce 1–3 small structural recommendations (likely about the doc format, not the spine). Each surfaces as a chip in the new UI. **Palle reviews each chip and decides apply / defer / reject.** I do not apply them automatically.

The test passes if:
- The parser correctly extracts the recommendations.
- Each shows in `/sieve-proposals` as an actionable chip.
- The pause primitive holds the session until at least one chip is resolved.
- The apply script's reversibility is tested by applying one move and rolling it back.

DECISION 3: is this test scope right? Or should the test cycle be a real spine sieve (e.g., the `softbodies` 33-artifact split that was deferred in the oscillation sieve)? Recommendation: the meta-test first, since it doesn't risk a real reorder while the new substrate is unvalidated.

## What this proposal does NOT include

To prevent scope creep within the build:

- **No automation of sieve generation.** The AI still writes sieve docs by hand; the chip parser only reads what's already there.
- **No machine-readable QFEP encoding.** Phase truths and qfep_term fields stay as prose for now.
- **No headset-walk verification.** Tonight's reorder still needs to be walked; that's separate.
- **No retroactive chips for tonight's seven moves.** They're already applied. The chip system applies to *future* sieve passes only. The proposal records get a `pre_existing: true` flag in their JSON if we backfill — but backfill is optional.

DECISION 4: backfill tonight's seven moves as pre-existing chips so the UI has real data to render, or start fresh with the test sieve? Recommendation: backfill as `applied + pre_existing: true` so the UI isn't empty on first load.

## Estimated build time

If decisions 1–4 all match the recommendations:

- Parser: 30 min (markdown table → JSON, straightforward)
- API route: 20 min (4 endpoints, follows chamber pattern)
- UI page: 60 min (chip rendering, apply/defer/reject buttons, status badges)
- Pause primitive: 30 min (write/read `ada_run/pause_holds.md`, integrate with `/loop` skill prompt)
- Apply script: 45 min (4 move types, backup logic, idempotent)
- Backfill of tonight's chips: 15 min
- Test sieve cycle: 30 min

**Total: ~3.5 hours of work.** Then the report blog.

## Hold

I will not start the build until Palle approves DECISIONS 1–4. The decisions are:

- **DECISION 1:** Path A (file-based pause) vs Path B (skill-coupled pause)? Recommend A.
- **DECISION 2:** Move types in v1 — phase/order/layer/unlock-edge, defer phase-truth/new-phase? Recommend yes.
- **DECISION 3:** Test scope — meta-sieve on doc/sieve_passes/ itself vs real sieve? Recommend meta-sieve first.
- **DECISION 4:** Backfill tonight's seven moves as pre-existing chips, or start fresh? Recommend backfill.

This document is the substrate that should have existed for tonight's reorder. By writing it before building, the hold mechanism is being demonstrated even though the tooling for it doesn't exist yet. The proposal is *itself the proof of concept* — if reading this and saying "yes to all four" feels different from saying "build and place them" did earlier, then the substrate's value is already clear.

If any decision shifts, the plan adjusts. The build doesn't start until the decisions land.
