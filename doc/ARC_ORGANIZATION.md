# ARC-AGI as a lens on map organization

> Companion note to `doc/COMPOSITION_LAWS.md` and the canon
> (`commons/data/composition_grammar.json`). Palle 2026-07-24: "Can we use
> arc-agi to think about how maps should be organized?" — yes, and the answer
> reorganizes how we think about the whole composition machine.

## The isomorphism

ARC tasks and Ada maps are the same kind of object: small discrete grids
whose meaning lives in objectness, symmetry, counting, topology. An ARC
solver searches a DSL of grid operations for the shortest program consistent
with a few examples. Our composer *is* such a program (spec → grid), and the
canon's eight operations *are* its DSL. We have been running ARC forward
without noticing.

## The inversion is the insight

We compose forward: spec → map → score. ARC thinks backward: given the grid,
find the shortest rule that explains it. Applied to maps:

**Organization = inducibility. A map is organized to the degree a walker can
induce its rule from partial experience of it.**

This retroactively explains every eye-verdict of the ten rounds:

- v1–v2 (the planes): rule = none. Nothing to induce. Dead — the eye said so
  before any metric could.
- v6 (the crescendo spiral): rule = "rooms grow clockwise." Induced after
  half the ring; the rest of the walk *confirms* it. Alive.
- The story arc (r5): rule = compression → release → rhythm → ascent →
  overlook. A narrative program, +0.18 under the rubric.
- The rubric's metrics (enclosure, rhythm, story, hall band) are *proxies*
  for inducibility. ARC names the underlying quantity they approximate.

## Sequences are few-shot tasks

An ARC task shows 2–4 example pairs, then a test input. A sequence shows 2–4
maps, then more. The player is the solver: the early maps teach the spatial
rule, the middle maps must **confirm and extend** it (variation within the
rule — else incoherence), and the last map may **break it meaningfully** —
the reveal. The mold was always this: the growth that exceeds measurement,
the input the induced rule cannot cover. Rule, confirmation, extension,
break: ARC's structure and narrative structure are the same structure.

## Core priors ↔ our laws

ARC's core-knowledge priors map onto the canon almost one-to-one:

| ARC prior | Canon law / mechanism |
|---|---|
| objectness | body / reach / role — the artifact is not its bounding box |
| symmetry | wallpaper groups; the track's paired galleries; mirror segments |
| topology / connectivity | SEAM, reach, the moat, door contracts |
| counting / ordering | order strategies (crescendo, rhythm, sequence) |
| goal-directedness | arrival-as-story; the walk as intention |

The canon is a priors catalog for space. That is *why* the laws transfer
across formats (gate, track) — priors are format-independent.

## The caution (the sieve, and the compression thesis)

ARC optimizes for the shortest program. The project's thesis says the queer
is the irreducible — what resists compression ("short seed, costly run").
These are not in conflict if we keep the layers apart:

- **Organize the frame so it compresses.** The shell — typology, order,
  walls, arrival — should be a short program the walker can induce.
- **Let the content stay irreducible.** The artifacts are the costly run; a
  mill is not summarizable by the room that holds it, and must not be.

Dark spot (Q3): if inducibility becomes a maximand, we flatten — perfectly
compressible maps are monotone corridors, scoreboard-shaped. So inducibility
must be a **band, not a maximum**: too low is noise, too high is monotony.
The sweet spot is roughly *one surprise per rule* — enough pattern to
induce, enough residual to stay alive.

## What to build (round-11 candidates, in order)

1. **The inverse composer (`grammar_fit`)** — for any existing map, search
   the canon DSL for the best-fitting program; report (a) the rule found,
   (b) its description length, (c) the residual — the mass the grammar
   cannot express. Every one of the ~1,700 maps gets an organization
   profile. Weakly-organized maps surface for rework; heavily hand-crafted
   maps get their residual *protected* — a conservation ledger for the
   irreducible, not a demolition list. Plugs directly into the map-dna
   per-map research tracker.
2. **Few-shot sequence continuation** — induce a sequence's spatial rule
   from its existing maps, compose the next map *in-rule*. The wizard gains
   "continue this sequence." Only honest after (1) exists to verify the
   induced rule is real.
3. **Inducibility as a banded metric** — from the walker's POV: given rooms
   1..k, how predictable is room k+1? Scored as a band (like hall share),
   never a maximand.

The measurement (1) comes first — it is what keeps (2) and (3) from being
circular. Same discipline as aura: observe before weighting.
