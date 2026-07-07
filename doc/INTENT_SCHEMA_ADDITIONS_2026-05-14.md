# `intent.md` schema additions — virtual/actual fields

_Added 2026-05-14, after [The virtual is what Ada is](/blog/2026-05-14-the-virtual-is-what-ada-is) and the sieve pass at `doc/sieve_passes/2026-05-14T08-00-00_virtuality-as-ada-ontology.md`._

Three new optional fields for `intent.md` files in `commons/maps/<MapName>/`. Each is *gestural prose*, not enumerative list — that's the discipline the sieve pass enforced (don't tame the virtual into a checklist).

## The fields

### `Virtual field:` — for principle maps

A 1-2 sentence statement of *what differential field this map opens*. Free prose. Names the axes of variation without enumerating their values. Lives on the map that introduces a principle.

Example (from `Facade_Assembly_Principle/intent.md`):

> *Virtual field: The differential field of all possible facades composable from six compositional moves — column orders × bay rhythms × hierarchy stacks × fenestration types × rustication surfaces × cornice/base framings. The field is continuous in each axis ... and a facade is one path through it. Naming the six axes is naming the dimensions of the virtual; the expression maps that follow are each a single position in that field, actualized with a body. The principle map does not enumerate the field; it opens it.*

What it is *not*: a list of supported parameters. A schema. A class hierarchy. The whole point is to *name what the principle makes possible* in language, not to flatten it into a JSON.

### `Actualizes:` — for expression and chamber maps

A 1-sentence pointer to *which principle map this map actualizes*, plus a short tag from the canonical actualization vocabulary. Lives on every expression map and on chamber maps that synthesize across a sequence.

Canonical actualization tags (small fixed set):
- `canonical` — the principle clean (e.g., `Facade_Classical`)
- `dramatized` — the principle exaggerated (e.g., `Facade_Baroque`)
- `hybridized` — the principle compounded with another (e.g., `Facade_Venetian_Gothic`)
- `surfaced` — the principle voiced as texture/surface (e.g., `Facade_Rustication`)
- `modularized` — the principle stripped to repetition (e.g., `Facade_NYC_Tenement`)
- `refused` — the principle critiqued or anti-actualized (e.g., `Facade_Critique`)
- `synthesis` — the principle held available for the player's composition (e.g., `Chamber_Facade`)

Example (from `Chamber_Facade/intent.md`):

> *Actualizes: Facade_Assembly_Principle, in the synthesis mode. Where the six expression maps each take one position in the virtual field, the chamber gives the player the means to take their own position...*

The tag is constrained (one of seven). The pointer + descriptive sentence is free.

### `Differentiation engine:` — for DNA-thread-anchored maps

Only present on maps anchored in a DNA / parametric-iteration research thread. Names the engine, its data root, its current iteration state. *Live process language* — describes ongoingness, not type.

Example (hypothetical, for a future tessellation map):

> *Differentiation engine: grammar-dna, iteration 17/∞. The map shows one current actualization from the engine's tessellation field; rerun the engine to generate adjacent actualizations. Data root: `data/grammar_dna/tessellations/`. Last iteration: 2026-05-13T13:32Z.*

This field is rare. It lives on maps that *render an output of a differentiation engine* — not maps that *teach* about the engine. The map itself is one path through the engine's virtual field; the field reading says so.

## Where these go (not yet automated)

These three are **optional, additive, non-breaking**. The audit pipeline at `tools/coherence_proposals.py` does NOT yet require them. They thicken the intent.md when present; they don't reduce the map's score when absent.

When the audit gains awareness of these fields (a future small parser extension), they become *additional axes of coherence checking* — does the expression map's `Actualizes:` pointer find a real principle map? Does the principle map's `Virtual field:` get described in the expression map's body? — but for now they live as durable prose on the principle/chamber/DNA-anchored maps that use them.

## Why these and not more

The sieve pass at `2026-05-14T08-00-00_virtuality-as-ada-ontology.md` surfaced six risks to the reframing. Two of them constrained schema design directly:

- **Q2 risk 4 — over-systematization:** *Adding a `virtual_field:` JSON key in intent.md schemas risks taming the virtual into a static descriptor.* Mitigation: gesture-like prose, not enumerative list. Honoured by these three fields.
- **Q2 risk 5 — loss of prescriptive force:** *Principle/expression is actionable; virtual/actual is descriptive.* Mitigation: keep action-language in workflow tools. Honoured by **not renaming** the chip UI's `apply / defer / reject` buttons.

Three fields, gestural, optional, descriptive. The schema is small on purpose. Adding more fields tomorrow is easy if a real need surfaces; adding them today would be over-fitting to the morning's blog before the work has tested it.

## What this does NOT introduce

- No JSON field changes anywhere
- No required validation
- No breaking changes to existing `intent.md` files
- No new vocabulary for chip UI, audit reports, or workflow tools
- No automated parser updates

The fields live as prose conventions in the markdown files. The substrate continues to function exactly as before; the maps that use these fields are *more legibly Deleuzian* without imposing that legibility on maps that don't.

## Two maps now carry these fields

- `commons/maps/Facade_Assembly_Principle/intent.md` — `Virtual field:` added
- `commons/maps/Chamber_Facade/intent.md` — `Actualizes:` added (tag: synthesis)

The two pass-2 maps (`Facade_Classical`, `Facade_NYC_Tenement`) — to be built next — will carry `Actualizes:` from inception (tags: canonical / modularized respectively).
