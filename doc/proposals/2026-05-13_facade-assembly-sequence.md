# Proposal — `facade_assembly` as a new sequence

_Drafted 2026-05-13, after [What the sequences look like when you visit them](/blog/2026-05-13-the-sequence-visits) and Palle's "yes, 1" sign-off on option (1) from that visit's close._

This is a proposal, not an implementation. Per the propose-hold-return discipline, **nothing gets written to spine JSON, sequence files, or new map folders until Palle signs off on D1–D5 below.** The 16 facade stubs in array_tutorial stay where they are until the discard step is explicit. The new sequence is named, scoped, and curated here only.

## The principle the sequence carries

Mosaics are arrays in stone — addressable cells with adjacency rules. **Facades are assembly** — hierarchical composition of parts: column orders, rhythm, fenestration, cornice, base. Not addressable cells. A vertical and horizontal syntax of components. The principle is *composition grammar applied to architectural form*.

This sits cleanly downstream of `boolean_surfaces` (4.7), which already teaches CSG = composition algebra. Facade assembly is what that algebra does when you point it at column orders and bay rhythm instead of generic primitives.

## The sequence shape (7-8 maps under the ≤10 cap)

| # | map | position | role |
|---|---|---|---|
| 1 | `Facade_Assembly_Principle` | intro/foundation | The rulebook map. Column orders, rhythm (bay spacing), hierarchy (base / piano nobile / attic), fenestration, cornice, rustication-as-surface. Small dense map, in the spirit of `Geometric_1`. |
| 2 | `Facade_Classical` | foundation | The canonical case. Symmetry, hierarchy, full column order. The principle clean. |
| 3 | `Facade_Baroque` | exploration | The principle dramatized. Bernini-style colonnade / rhythm becoming syncopation. |
| 4 | `Facade_Venetian_Gothic` | exploration | The principle hybridized. Gothic vocabulary inside Italian rhythm. |
| 5 | `Facade_Rustication` | exploration | Surface as voice. Florence marble OR Naples diamond rustication. Hierarchy preserved; texture carries the argument. |
| 6 | `Facade_NYC_Tenement` | exploration | The principle modularized. Same bay stacked five times. Repetition without ornament. |
| 7 | `Facade_Critique` | integration | The principle pushed past architecture into critique. Superstudio's continuous monument, or Memphis Totem refusing hierarchy. |
| 8 | `Chamber_Facade` | synthesis | The chamber closing. Synthesis of the rules walked. |

Six expression maps + one principle map + one chamber. Eight total. Under the cap by two.

Critically: **every one of these is a NEW map that has to be built fresh**, even if the name overlaps with an existing facade stub in `array_tutorial`. The old stubs have no working artifact, no text. The new maps need:
- a real `intent.md` written from the principle's vocabulary
- working artifacts (architectural primitives that resolve in the registry)
- a real `blurb.md`, `summary.md`, `critical.md`

So this is **not migration**. The 16 facade stubs get discarded; 6-8 new maps get authored.

## The curation rationale

I dropped 10 of the 16 stub names:

- **`Facade_capri_whitewash`, `Facade_galleria_vittorio_emanuele`, `Facade_florentine_polychrome`** — overlap with the regional / historical maps already chosen.
- **`Facade_continuous_monument`** — kept as alternate for slot 7; chose Superstudio Grid grouped under one critique map instead.
- **`Facade_painted_vault`** — vaulted ceiling, not really a facade.
- **`Facade_decon_fragment`** — partial form; the critique slot already does fragmentation harder via Memphis/Superstudio.
- **`Facade_gothic_portal`** — kept the gothic vocabulary in Venetian Gothic; portal-alone is too narrow.
- **`Facade_florence_marble`** — competes with Naples diamond rustication for the surface-as-voice slot; pick one (D3 below).
- **`Facade_bernini_colonnade`** — folded into the Baroque slot.
- **`Facade_memphis_totem`** — could split off Critique slot if you want 7 expressions instead of 6. (D4)

The principle: each surviving expression map shows what the assembly grammar does that the others don't. *Classical = the rule clean. Baroque = the rule dramatized. Venetian Gothic = the rule hybridized. Rustication = the rule's surface. Tenement = the rule modularized. Critique = the rule's refusal.* Six modes of the same principle, like the five colors of the λ_edge phase from earlier today.

## Where it slots in the spine

Two options:

**Option A — as branch off `boolean_surfaces`.** The spine main line stays at F_order (1–4.7) → oscillation (5–6) → … as it is now. `boolean_surfaces.unlocks` adds `facade_assembly` as an optional follow-on branch. Same pattern as `proceduralgeneration.unlocks: [isosurfaces, ...]` used to work. The player who finishes boolean_surfaces and wants to see what composition does at architectural scale walks this branch. **Doesn't bloat the spine.**

**Option B — main spine, order 4.8.** Inserts between `boolean_surfaces` (4.7) and `forces` (5). Every player walks it. **More structurally committed; harder to remove later.**

Recommendation: **A.** The spine reads as one argument and shouldn't gain side-arms unless they're load-bearing. Facade assembly is rich expressive material but the QFEP arc doesn't *require* it. Branch is correct.

## Prerequisites

A player walking `facade_assembly` should have walked:
- `primitives` (the cube, the column, the plane)
- `transformation` (vertical and horizontal positioning)
- `array_tutorial` (1D / 2D / 3D understanding — bays are 1D arrays of components)
- `boolean_surfaces` (CSG = composition substrate)

## The decisions, before any build

### D1 — Name

- `facade_assembly` — what we've been calling it; clean, says what it does
- `architecture_facades` — more discoverable in search
- `assembly_grammar` — more abstract; signals "this is about composition, with facades as the example"
- `compositions` — even more abstract

**Recommendation:** `facade_assembly`. The "assembly" word does work: it names the principle without leaving the substrate.

### D2 — Branch or main-spine slot

- A: branch off `boolean_surfaces.unlocks`
- B: insert in main spine at order 4.8

**Recommendation:** A (branch). Spine stability matters; assembly is an expressive specialization, not part of the QFEP argument.

### D3 — Rustication map: Florence marble or Naples diamond?

Florence: smooth marble panels, structural; Naples: pyramid-bossed rustication, defensive-decorative. They're different *moves* of the same principle. Pick one for now and let the other be a future addition.

**Recommendation:** Naples diamond rustication. More distinctly textural — the surface-as-voice claim lands harder.

### D4 — Six expression maps or seven?

Six: Classical / Baroque / Venetian Gothic / Rustication / Tenement / Critique. Seven: split Critique into two (Superstudio + Memphis as separate maps).

**Recommendation:** Six. The ≤10 cap gives us 8 slots; principle + 6 + chamber = 8 exactly. Two slots empty leaves room for one expansion when the visit-walk reveals what's missing. Splitting Critique upfront wastes the slack.

### D5 — Build order

When the sequence ships:

- *first build pass:* `Facade_Assembly_Principle` + `Chamber_Facade` only. (The principle map and the chamber establish the frame.)
- *second pass:* `Facade_Classical` + `Facade_NYC_Tenement` — the two opposite-ends-of-the-spectrum expressions (canonical / modularized).
- *third pass:* the three middle maps (Baroque, Venetian Gothic, Rustication).
- *fourth pass:* Critique.

This way the sequence is *walkable end-to-end* after pass 1 (just principle + chamber, like Geometric_1 → Chamber). Each subsequent pass adds an expression without breaking the frame.

**Recommendation:** yes, this build order, but the four-pass plan is informational — the sequence file gets declared with all 8 slots at proposal time; the artifacts get authored in pass order.

## What this proposal does NOT include

- **The discard of the 16 facade stubs from `array_tutorial`.** That's a separate operation. After this proposal lands and the new sequence is real, the discard becomes safe; before that, the stubs are at least *labeled* (even if broken) and discarding them now would leave an unnamed gap. So: this proposal lands first, *then* the stubs go.
- **The artifact build for `Facade_Assembly_Principle`'s in-world primitives.** That's a chamber/build session, not a sequence proposal.
- **Anything about the wallpaper / Pompeii-interior maps.** Those are the OTHER half of the array_tutorial cleanup. Separate proposal, separate decisions.
- **Any rewrite of `boolean_surfaces.unlocks` or the spine `phases.relation` block.** Light JSON moves that happen at apply time, not proposal time.

## Hold

Five decisions (D1–D5). I will not write any JSON or scaffold any map files until Palle picks on each. Recommendations are stated; pick or override.

This document is the substrate the previous cycle's failure was missing. Tonight's structural addition to the spine is being held *before* commit, not after.
