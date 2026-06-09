# Bracelet Garden Modifiers — design

> Persisted design memo. Two threads: (A) the QFEP grounding for in‑VR grid editing
> as *caretaking*, and (B) the architecture for representing bracelet **modifiers**
> (colorize, shift, subdivide, normalize, transform, scale, rotate, random colors)
> in `map_data.json`. **Core‑grid rule applies** (`CLAUDE.md`): the modifier pass is
> grid‑adjacent — discuss + notify before wiring it into `GridSystem.gd`.

---

## A. The QFEP grounding: editing as tending **λ** (the living edge)

In QFEP (`QFE = F − λ·E(S) + φ·dE(S,t)`) the player editing the grid is operating **λ**
by hand — the order↔chaos balance. *Life exists at λ ≈ 0.3–0.5.* A garden is that band:

- all order (tidy grid, λ→1, pure F) → sterile;
- all chaos (overgrown, λ→0) → loses identity;
- the living edge (λ≈0.3–0.5) → it blooms, creatures arrive, it sings.

**Caretaking = keeping the place at the living edge.** The catalyst bracelet becomes a
**λ‑dial in the hands** rather than a tool that imposes. Spine home: the **λ_edge →
integration hinge** (`lsystems` 9 = grammar‑growth, `proceduralgeneration` 10 = constrained
placement, `morphogenesis` 11 = form from local rules); reflexively the **Self‑Q** at
`qfeplaboratory` (16) — tending the world that shapes the next maker.

Design moves (hook existing systems — `BiomeRingComponent`, `soft_stages.json`,
`NatureRenderer`, `CritterEntity`, the becoming/catalyst arc):
1. **Placed structure becomes habitat** — left cubes grow moss/flowers; creatures nest.
2. **The grid has a felt λ‑state, never a score** — sparse=grey/quiet, tangled=dark/restless,
   living band=warm light + motes + thickening soundscape. **No number.**
3. **Bracelet as a caretaker's hand** — cube=plant, wedge=terrace, off=rest, + tend/transplant;
   removal = *compost* (dissolve to motes), not a hard delete.
4. **Patina = memory = φ·dE** — left structure weathers; the grid remembers care.
5. **Creatures as the living reward** — the FOE→FRIEND arc as the sign of good habitat.

**Sieve:** (1) thickens water — λ becomes bodily. (2) foreclosed: *the score* — "improve
niceness" must NOT become "rate my garden N/10"; foreclose the metric, keep the feeling,
keep it plural. (3) dark spot stays generative — never define "the correct garden"; leave
room for weird, ugly‑beautiful, overgrown ones.

---

## B. Modifier architecture: a non‑destructive **operation stack**

### The problem with the two obvious options

**Not the utilities layer.** Utilities are per‑cell *navigation/function* codes (spawn,
teleporter, ramp). Modifiers are heterogeneous *appearance + geometry transforms*. Folding
them in pollutes utility semantics and — fatally — a per‑cell grid cannot express a
field op like `subdivide the whole grid` or `normalize`.

**Not a 4th per‑cell `modifiers` grid either.** Same wall: most of the listed modifiers are
**region/field ops**, not per‑cell. Categorize them:

| Modifier | Scope | Kind |
|---|---|---|
| colorize, random_colors | per‑cell / region | appearance |
| shift | cell / region | displacement |
| subdivide | region / whole‑grid | resolution |
| normalize | whole‑grid | **reset** (flatten heights, clear mods) |
| transform / scale / rotate | region / selection | affine |

A per‑cell array holds colorize fine but can't hold "subdivide ×2" or "rotate this region 90°".
And **order matters**: subdivide→colorize ≠ colorize→subdivide. A parallel grid loses order.

### The recommendation: an ordered, non‑destructive op list

Add ONE new top‑level section, an **ordered list** of operations applied as a pass over the
base three layers at load/render time. The base `structure`/`utilities`/`interactables` stay
**untouched** (respects the core‑grid rule — the modifier pass is additive, reversible).

```jsonc
{
  "layers": { "structure": [...], "utilities": [...], "interactables": [...] },
  "modifiers": [
    { "op": "colorize",      "target": { "cells": [[3,4],[3,5]] }, "params": { "color": "#e08a2a" } },
    { "op": "random_colors", "target": "all",                     "params": { "palette": "warm" }, "seed": 7341 },
    { "op": "subdivide",     "target": { "region": [2,2,8,8] },   "params": { "factor": 2 } },
    { "op": "rotate",        "target": { "region": [2,2,8,8] },   "params": { "deg": 90, "pivot": "center" } },
    { "op": "shift",         "target": { "cells": [[5,5]] },      "params": { "dx": 0, "dy": 1, "dz": 0 } },
    { "op": "normalize",     "target": "all",                     "params": {} }   // reset: flatten + clear mods
  ]
}
```

- **target**: `"all"` | `{ "region": [r0,c0,r1,c1] }` | `{ "cells": [[r,c],…] }` — one uniform addressing scheme covers per‑cell *and* field ops.
- **order is the list order.** "combis" = just multiple ops in sequence. Composition is free.
- **normalize** = a reset op (flatten heights + drop appearance mods). The bracelet's "make it a plane grid again" is `{op:"normalize"}` — or, cheaper, truncate the stack.
- Each op is small, declarative, and engine‑agnostic.

### Why this is **predictable** (the word in the question)

1. **Deterministic replay** — the same stack always yields the same grid; it's a pure function of (base layers, ops).
2. **Seeded randomness** — `random_colors` carries a `seed`, so "random" is reproducible. No seed → engine stamps one on apply, then it's fixed.
3. **Previewable** — because it's non‑destructive, you can apply the stack to a *copy* and show the result before committing: the player (or the editor) **predicts** the outcome, then commits. Undo = pop the last op.
4. **Diffable / serializable** — the bracelet appends one op per gesture; the stack is the literal, legible history of edits.

### QFEP tie‑in (why this isn't just plumbing)

The modifier stack **is the λ‑tending record.** colorize / subdivide / random_colors push
variety (E); normalize pulls back toward order (F); the ordered history is φ·dE — the rate
and shape of change, visible. So the architecture and the garden vision are the same object
seen twice: *the stack is the trace of care.*

---

## Open decisions (need your call before building)

1. **Application point** — load‑time bake (apply stack → effective layers, cache) vs render‑time
   overlay (keep base pristine, recompute on edit). Bake is simpler; overlay is more "live".
   *Grid‑adjacent → notify before wiring into `GridSystem.gd`.*
2. **Subdivide semantics** — does it change the logical grid resolution (affects pathfinder!)
   or only the visual mesh? Logical subdivide is powerful but touches reachability — careful.
3. **Per‑cell density** — if colorize ends up covering most cells, add an *optional* compact
   per‑cell `color` sub‑grid as a cache derived from the ops (not authored directly), keeping
   the op list canonical.
4. **Bracelet UX** — which stone/gesture appends which op; the compost/undo gesture = pop.

## First slice to prove it
A tiny sandbox map + a `modifier_stack.gd` that reads `map_data.json.modifiers`, applies
colorize + normalize + random_colors(seed) non‑destructively at load, with undo = pop. No
core‑grid change yet — it reads the new section and tints/flattens on top.
