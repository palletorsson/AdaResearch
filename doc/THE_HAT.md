# The hat: from a sentence to a thing standing on a floor

*2026-10-27. Palle: "Imagine you could just take it out of the hat. How would that hat be made to close the loop faster?"*
*Produced by a workflow: five readers (grammar, loop, eyes, friction, velocity), three competing designs (grammar-first, loop-first, catalog-first), three judges, a synthesis and a critic. Judges' totals: loop-first 95, grammar-first 87, catalog-first 66. The critic's verdict was "revise before building"; its corrections are folded in below.*

## What the readers measured

| fact | number |
|---|---|
| modular terms | 220 (213 committed, 7 handmade pallets failing the probe) |
| terms placed in the Void | 0 of 1505 records |
| `prefab` and `light` primitives used | 0 times |
| terms that take arguments | none: every variant is a full copy (a pallet is 16-52 KB) |
| property links between objects | none: only physical joints by child index |
| live revisions since 23 Oct that reached a running game | 2 of 110 |
| making : instrumenting, commits since 15 Oct | about 1 : 3.6 |
| APK export | 16-18 min, about 885 MB |

The carrier already works in code: a record `mod_<term>` with `config.expression` is built by `commons/modular/composite.gd` (`apply_grid_config`, lines 72-80 and 98-108) after `floor_content.gd` copies the record's config (line 471, applied around 566). The proposal lane can add a record. The grammar can say geometry, repetition, fields and preset engines. It cannot say parameters, property-to-property links, events or time.

## The hat, as decided

The hat is a **loop**, not a bigger grammar and not a catalogue. A sentence becomes one expression in the modular grammar, the expression stands on a floor, the agent looks at it, a person judges only what only a person can judge, and every verdict is kept.

1. **A lab floor that belongs to the agent.** A scratch storey of the Void where draws stand without spending Palle's Accept. Palle judges only what graduates to a curriculum floor. *This is the critic's main correction, and it answers "your own lab".*
2. **One expression per draw.** A combination is always one expression, with registry artifacts entering as `prefab` leaves. Never two artifacts placed side by side.
3. **Eyes.** One generic bench run per draw: build, census (every body has a collider, every prefab resolved), eye-level shots from three standpoints, decoys that must fail. No probe per subject.
4. **Memory.** A ledger of kept and refused draws, harvested from Accept, Reject and memos. A kept tuple (fixture, lamp, operator, chapter) becomes a reusable strategy: the list of successful strategies, machine-readable.
5. **Grammar grows only when a draw needs it.** First `stand` (seat a work on a fixture by measured bounds), then `bind` (one property drives another, with a frozen twin beside it as the visible control). Ports (parameters) when a draw needs a family.

## Corrections the critic forced

- **Fixtures do not resolve today.** The 28 `prop:*` spawn items have no scene, so a `prefab` leaf of a workbench builds the labelled cream fallback box. Props are built by `SetDressing.build` from `propKind`. `builder.gd` needs that branch before any fixture can stand inside an expression.
- **The first draw must be a real crossing on a floor that lacks it**, not a re-derivation of an installed work. 10 PRINT on floor 79 already stands as a walkable wall maze, so the proposed first draw was refused. Good targets: the 118 maps with no term in MODULAR_TUTORIALS.md, or thin floors such as Random_Remove (3 works).
- **Verify the carrier on the main tower**, not through a trial probe (a trial takes the `museum_import` branch, a different code path).
- **Content first, tools after.** Day one stands one hand-written expression through the existing proposal lane and looks at it. The script and bench are extracted from what that took, not built ahead of it.
- **Something must be listening.** A revision applies only where a game with `--vr-link` is running. Starting the desktop Void is part of the loop.
- **The agent draws too.** Not only "Palle says a sentence": the agent proposes crossings itself (term × term, term × registry artifact) on its lab floor.

## First slice (days, not weeks)

1. Add a lab floor to the tower, owned by the agent, through a forum ask to the Void's agent.
2. Stand one hand-written expression there through the proposal lane, desktop running, and screenshot it. Done when it stands and the picture exists.
3. Make it a crossing: one term with one registry artifact as a prefab leaf, plus the SetDressing branch so a fixture (workbench, scaffold) is real.
4. Only then: the bench script, the ledger row, `stand`.

## What only Palle judges

Whether it reads as the intent, whether it is strange in a good way, whether it belongs to the floor's argument, and scale and feel at eye height. One gesture: Accept or Reject in the strip he already uses, or a one-line memo.

## Sieve

Thickens: a sentence becomes a walkable thing, refusals are kept so the space of what fails becomes navigable, and staging becomes something to think with. Foreclosed: time, events and sequencing between works; relations beyond one bound pair until a draw needs more. Dark spot: what reads only in motion, sound or fog is invisible to stills, and the tuple records how a work stands, not why it belongs. That stays in Palle's sentences and memos, on purpose.
