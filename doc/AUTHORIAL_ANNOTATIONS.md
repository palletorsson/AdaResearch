# Authorial Annotations

The `@`-prefixed utility codes declare authorial intent that the map pipeline must respect. They are invisible at runtime — the player never sees them — but they shape generation, validation, capture diffing, and the constraint solver.

`a:` was already taken (walls). `@` is the authorial namespace.

## Why

Until now, the pipeline could infer what artifacts need (contract inference → 97% coverage) and what kind of scene each artifact wants (archetypes → 8 kinds). It could not read the author's intent about the **whole map**: which cells must stay empty, which region is a golden sample, which artifact is load-bearing, where the breath is, what style to match, what sequence this map secretly echoes. The `@` codes are where the author speaks to the generator.

## Vocabulary

Codes live in the `utilities` grid layer. Parameters are `:`-delimited.

### Core three

| Code | Params | Meaning |
|---|---|---|
| `@void` | — | Argued emptiness. Cell MUST stay empty. Generator, placement rules, and biome layers skip. |
| `@look` | `W:D` | Change-detection anchor. Capture pipeline diffs this `W×D` region between runs and surfaces deltas for review. |
| `@sample` | `[W:D]` | Locked reference region. Generator copies verbatim when scoring similarity. Inline golden corpus. |

### Constraints

| Code | Params | Meaning |
|---|---|---|
| `@must` | `token` | Required artifact slot — generator must place `token` here. |
| `@block` | `token` | Exclusion — `token` may not appear on this map. |
| `@signature` | `token` | Load-bearing artifact — protected from dimming/shuffling during composition. |

### Rhythm & style

| Code | Params | Meaning |
|---|---|---|
| `@breath` | — | Intentional sparse zone. Biome layers dim here. |
| `@echo` | `sequence` | Run an earlier sequence's biome layers at this stage. |
| `@style` | `kusama\|rams\|bauhaus\|escher\|pompeii` | Palette/density hint for biome layers. |
| `@dense` | `0..1` | Per-map density multiplier. |
| `@seed` | `integer` | Deterministic seed for surrounding generation. |

## How the pipeline reads them

1. **Generator** — reads hard constraints (`@must`, `@block`, `@void`, `@signature`) as a constraint set. Solves for minimum-edit placement that satisfies all. Fails loudly if unsatisfiable rather than producing a plausible-but-wrong map.
2. **Placement rules** — skip `@void` cells entirely. Never elevate, never wall.
3. **Biome accrual** — reads `@breath` to dim layers, `@echo` to time-travel the layer stack, `@style` to bias palette/density, `@dense` to scale mote/instance counts.
4. **Capture pipeline** — when `@look` regions exist, diffs only those zones between runs. Non-`@look` drift is allowed and ignored.
5. **Reverse extractor** (`tools/map_to_spec.py`) — reads `@`-codes as the highest-priority signal when building the map's spec. Any `@` cell becomes a declared authorial constraint in the spec output.

## Usage

In `map_data.json` the utilities layer carries the annotations alongside spawn, teleporter, etc.:

```json
"utilities": [
  [" ", "@void", "@void", "@void", " "],
  [" ", " ",    "@signature:rotation_gimbal", " ", " "],
  ["s", " ",    " ",     " ",     " "],
  [" ", " ",    "@sample:3:2", " ", " "],
  [" ", " ",    " ",     " ",     "t"]
]
```

This says: three cells in row 0 must stay empty, `rotation_gimbal` is the load-bearing artifact at (2, 1), a 3×2 golden reference sample is anchored at (2, 3), spawn at (0, 2), teleport at (4, 4).

## Round-trip confidence

Run `python tools/map_to_spec.py <MapName> --check` to see how much of a map's intent is **declared** vs **implicit**:

```
[ok]  Point_One -> doc/specs/maps/Point_One.spec.json
      intent_ratio=0.111 declared=1 implicit=8 free_cells=29 verdict='mostly inferred'
```

`intent_ratio = declared / (declared + implicit)`. When a map's intent_ratio climbs above ~0.5, the generator has enough signal to reproduce it from the spec alone. Below that, too much is inferred from placement heuristics — a generator guess could produce something superficially similar but semantically wrong.

**Target:** golden-corpus maps should sit at `intent_ratio >= 0.7`. Reaching that is the authorial work — deciding which artifact is really signature, which cells are really void, which region is really sample-worthy.

## When to use which

- **Reach for `@void`** when you've *argued* a cell should be empty — not just left it blank. Leaving a blank is ambiguous; `@void` is declarative.
- **Reach for `@sample`** when a cell arrangement is **exemplary** — you want it preserved verbatim and used as training signal for similar maps.
- **Reach for `@signature`** when the artifact at a cell is **load-bearing** — the map is about this artifact, and losing it breaks the teaching.
- **Reach for `@look`** when you suspect drift — you want to know if this region changes between generator runs.
- **Reach for `@breath`** when you've deliberately created an empty area for pacing — the generator should not "helpfully" fill it.
- **Reach for `@echo`** when the map is meant to recall an earlier sequence — seq-12 genetic programming that echoes seq-7 randomness, seq-17 QFEP that echoes seq-1 void.
- **Reach for `@style`** when the map has a specific aesthetic register — Pompeii mosaic floor, Dieter Rams rack, Kusama dot field.

## Priority

1. **Now:** `@void`, `@sample`, `@signature` — the three highest-leverage (negative space, locked positive, protected core)
2. **Next:** `@look` + differential capture pipeline
3. **Later:** `@must`/`@block` + constraint solver in the generator
4. **Last:** rhythm codes (`@breath`, `@echo`, `@style`, `@dense`) once signature placement is trusted

Start with ten maps annotated by hand. See if the `map_to_spec.py` round-trip on those ten reconstructs what you authored. If yes, scale. If no, the vocabulary is wrong — collapse codes, don't add more.
