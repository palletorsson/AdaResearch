# Spatial Contract — architecture audit

> Written 2026-08-11, before any code changed. Every number here was measured
> against the working tree, not estimated.

## The finding in one sentence

The repo does not lack a spatial contract. It has **six of them**, they disagree
by up to 78 cells on the same artifact, and each layer reads a different one.

## 1. The six vocabularies

| # | Where | Coverage | Shape | Read by |
|---|---|---|---|---|
| 1 | `registry[*].measurements` | 1753 / 2718 | `aabb_size` [w,h,d], `grid_cells` [w,d] | `spine_auto_research`, museum runtime |
| 2 | `registry[*].spatial_needs` | 2261 / 2718 | `footprint_cells` (scalar), **directional** `clearance`, `platform`, `wall_backing`, `orientation`, `preferred_zone`, `player_position` | `placement_research`, `place_artifacts`, `build_curation_bays`, **and GDScript at runtime** |
| 3 | `registry[*].spatial_profile` | 1539 / 2718 | `dir_group`, `range`, `density`, `min_clearance` (**scalar**), `stack_priority`, `approach_dir` | only `spine_auto_research`, `map_grammar/footprints`, `build_wall_faces` |
| 4 | `registry[*].footprint` / `parameters.footprint` / `footprint_measured` | 1076 / 1273 / 957 | `[w,h,d]` triples | `endless_museum.gd` reads **`parameters.footprint`** |
| 5 | `dressing_rooms/*.json → placement_contract` | **34** / 2659 | `hard_zone_m`, `preferred_zone_m`, `allowed_modes`, `interaction_faces`, front/rear clearance, `circulation`, `required_support`, `neighbor_policy` | `placement_negotiator.py` only |
| 6 | `commons/data/museum_contract_pilot.json` | **12** artifacts | `body_envelope_m`, `sweep_envelope_m`, postures, view distance | `museum_contract_pilot.py` only |

**Vocabulary 5 is the richest and vocabulary 2 is the broadest, and nothing reads both.**

## 2. How badly they disagree

Of the 1728 artifacts carrying both a measured AABB and a `spatial_needs.footprint_cells`:

- **230 (13%) understate their true width by more than 50%.**
- **326 sit pinned at exactly `footprint_cells: 9`** while measuring wider than 9 cells —
  the fingerprint of `sync_footprints.py --cap=9`. The cap is not a measurement, it is a
  ceiling, and every downstream placer has been reading it as a measurement.

Worst cases (declared cells → measured cells):

```
combine_portals    9  →  [8, 87]
hallway_scene      9  →  [6, 80]
pokemon_studio     9  →  [62, 50]
earths_delight     9  →  [61, 60]
```

And the hand-authored contracts disagree with the measurements too:

```
lambda_slider   measured AABB 8.0 × 8.0 × 8.0 m
                placement_contract.hard_zone_m = [1, 3, 3]
```

The contract claims a 1 m-wide object. Godot measured eight metres. Whoever is right,
**the negotiator currently trusts a third number** — `measured_body_m` out of a static
release report in `ada_run/museum_aaa_pass/`.

## 3. What already exists and is good

This is the part worth protecting. Several pieces of the target architecture are already
built and working:

- **`tools/placement_negotiator.py` (551 lines, 10 passing tests)** already implements the
  three-zone model (`occupied_body` / `hard_zone` / `preferred_zone`), a rule-trace
  explain record, an escalation ladder (move → rotate → grow → shrink → wall exception →
  reject), and the explicit `apply_wall_exception` for collapsing rear clearance. Section 2,
  5 and 8 of the brief are largely *already here*. Its limits: zones are bounding-box
  triples rather than directional cell masks, and it reads only the 34 hand-authored
  dressing rooms against a static offers file.
- **`tools/build_uffizi_prop_placement_pilot.py` (831 lines)** already treats a wall as a 2D
  `(u, v)` surface with a feature field, prop rails, semantic anchors, mounting-height
  bands and accepted/rejected records. Section 6 is *already here* — but hardcoded to one
  map (`Museum_AAA_Uffizi_Cohort_10`) and one wall (north).
- **`commons/data/template_patterns.json`** already expresses floorplans as cell-role tiles
  (`''` void, `1` floor, `1s` floor slot, `2s` podium slot, `3s` high podium slot, `4` wall)
  across ~180 named architectural grammars. **The floorplan already exposes placement
  candidates.** Section 4 needs selection and parameters, not a new format.
- **`commons/data/spine_artifact_order.json`** (799 rows) + `artifact_relations.json` +
  `artifact_order_policies.json` already provide the canonical 1D order with lineage.
  Section 3 needs no new system.

## 4. What is actually broken

1. **No resolver.** Nothing converts the six vocabularies into one contract, so each tool
   picks a favourite and silently gets a different artifact.
2. **The assembler reasons about placement.** `endless_museum.gd` `_pick_pool()` and
   `_deal_segment()` do size-fitting at runtime in GDScript against `parameters.footprint`
   — a vocabulary *no* Python placer writes. This is the section-7 violation.
3. **Clearance collapses to a scalar** in `spatial_profile.min_clearance` even though
   `spatial_needs.clearance` next to it is already directional.
4. **Three masks are three boxes.** The negotiator compares volumes, so it cannot express
   "free in front, flush at the back".
5. **The two pilots are unreachable.** `museum_contract_pilot.json` has zero consumers
   outside its own compiler; the wall pilot cannot run on a second map.

## 5. Verdict per component

| Component | Verdict |
|---|---|
| `measure_artifact_aabbs.py` | **Unchanged.** It is the only source of measured truth. |
| `derive_spatial_profile.py` | **Unchanged for now, demoted later.** Keep writing `spatial_profile`; it becomes one input to the resolver, not a rival contract. |
| `placement_negotiator.py` | **Extend.** Keep `negotiate()` and its 10 tests exactly as they are; add a cell-mask layer around it. |
| `build_uffizi_prop_placement_pilot.py` | **Generalise later.** Its `(u,v)` surface model is the wall domain; lift the model, leave the pilot running. |
| `template_patterns.json` + `map_grammar/ops.py` | **Unchanged.** Already the floorplan grammar. |
| `spine_artifact_order.json` + relations | **Unchanged.** Already the exhibition brief source. |
| `museum_contract_pilot.json` | **Merge, then deprecate.** Its 12 hand-authored envelopes become seed overrides in the resolver. |
| `spine_auto_research.py` | **Keep separate.** Structural *research* across unrelated grammars — explicitly not the production museum path. |
| `endless_museum.gd` `_pick_pool` / `_footprint_of` | **Deprecate the reasoning, keep the stamping.** Should consume a resolved plan. |
| `sync_footprints.py --cap=9` | **Flag as harmful.** The cap silently manufactures wrong numbers. |

## 6. The smallest missing abstractions

Exactly two, plus one wiring job:

1. **A contract resolver** (`tools/spatial_contract.py`) — one function, `resolve(lookup)`,
   that merges all six sources in a fixed precedence with **per-field provenance**, so a
   manual value always beats a derived one and every number can say where it came from.
2. **A cell rasteriser** — turns a resolved contract + rotation + mode into the three
   *masks* the brief asks for (physical / circulation / presentation) as actual cell sets,
   so directional clearance survives contact with the grid.
3. **Wiring**: floorplan slots → offers → negotiator → diagnostics → map → capture.

Everything else in the brief already exists in some form and should be reused.

## 7. Precedence rule adopted

Following the `grid_substrate_runner` precedent — operate on the existing substrate rather
than build a parallel one — the resolver **reads** the existing stores and writes nothing
back to them. Precedence, highest first:

```
1. dressing_rooms/<x>.json → placement_contract   (hand-authored)
2. museum_contract_pilot.json                     (hand-authored, 12)
3. registry.spatial_needs                         (broad, part-manual)
4. registry.spatial_profile                       (auto-derived)
5. registry.measurements                          (measured truth — geometry only)
6. schema defaults
```

Measured geometry always wins for **body size**; hand authorship always wins for
**intent** (modes, faces, clearance). Those are different questions and the old systems
conflated them.

---

# Part 2 — what the first vertical slice found

Built after the audit: `spatial_contract.py` (resolver + three masks),
`spatial_floorplan.py` (enfilade grammar, slots, wall surfaces),
`spatial_negotiation.py` (escalation ladder), `spatial_slice.py` (runner + diagnostics
+ map compile). 27 tests, and the incumbent `placement_negotiator.py` is untouched with
its 10 still green.

Three artifacts, three genuinely different spatial cases, one negotiator, no
artifact-specific code:

| artifact | case | outcome |
|---|---|---|
| `bias_visualizer` | freestanding object | island slot, step 1 |
| `science_screen` | wall-oriented panel | bay end wall, `against_wall`, wall rect + 0.75 m mount |
| `neural_network_visualization` | large, 10 cells wide, 8.1 m tall | needed both expansions |

## Corpus-wide disagreement, now measured

Running the resolver over all 2698 artifacts: **525 have sources that disagree
materially** — 444 where `spatial_needs.footprint_cells` understates the measured area,
81 where a scalar area cannot express a measured shape (a 10×1 strip and a 3×3 block
both read as "9"). Every one is recorded on the contract rather than silently resolved.

## Two faults only the capture could find

Both passed every 2D check and were wrong in 3D. This is the argument for keeping the
capture step inside the pipeline rather than after it.

1. **Off-origin geometry.** `neural_network_visualization` has
   `measurements.aabb_center = [4.5, 0, 0]` — its mesh sits 4.5 m east of its node
   origin. The negotiator reserved cells 2–12; the artifact stood on 7–17. A plan
   reasons about a **body**; a map token positions a **node**. The contract now carries
   `centre_offset_m` and the compiler converts.
2. **`:0.0` is not a harmless default.** `GridInteractablesComponent.gd:1253` treats any
   third token field as manual control and **switches auto-grounding off**. The
   convention copied from the older pilot silently un-grounded every artifact it placed.
   A two-part token is now emitted unless a wall mounting height was actually computed.

A third, found by looking at the iso capture: the negotiator was purely planar, so an
**8.1 m artifact in a 4 m room** scored a perfect placement while sticking out through
the roof. There is now a `body_fits_under_ceiling` hard rule, and the room can grow
upward as well as outward — the walls rose to 9 m, and the compiled `structure` cells
follow, because a cell's value is its height in cubes and `GridSystem.cube_size` is 1.0.

## Status against the milestone

Everything in section 12 of the brief is met: shared schema, auto-derived with manual
override and provenance, floorplan candidates, one negotiator for wall and floor alike,
three distinct envelopes, expansion, explained decisions, floor and wall diagnostics,
Godot instantiation, valid spawn→exit traversal (project pathfinder: OK, 0 issues), and
multi-angle captures that now match the plan.

**Not done, deliberately:** no catalogue migration, `endless_museum.gd` still does its
own dealing, and the wall pilot is still map-specific. Those are the next steps, not
this milestone.

---

# Part 3 — corrections after reading the encyclopedia pages

`/museum-contract-pilot`, `/museum-aaa-pass`, `/museum-wall-kit`,
`/template-pattern-editor` and `/template-maps` show a corpus considerably larger than
Part 1 found. Four corrections followed, three of them bug fixes.

## The seventh vocabulary

`commons/artifacts/artifact_spatial_contracts.json` — 14 artifacts, missed in Part 1.
It is the only store that already writes `footprint_cells` as an **oriented `[w, d]`
pair** rather than a scalar area, and it carries `directional_profile`
(full_circle · half_circle · cone · corridor · ambient), a `default_contract`, and —
critically — `rotation_semantics`.

## Correction 1: the rotation convention was mine, and it was wrong

`rotation_semantics` declares **0 = south, 90 = west, 180 = north, 270 = east**,
"matches map token convention used by interactables". Part 2 had assumed rotation 0
faced −z. That is 180° out, and it silently mirrors every wall placement: `science_screen`
(locked to rotation 0) was being sent to a south-facing wall when the declared convention
puts its back to the north. `ROTATION_FACING` and `side_dir()` now derive every
front/back/left/right band from the declared table, and the tests assert the table
rather than a local habit. Under the fix it lands on the bay's north-facing head wall.

## Correction 2: sweep envelope

The AAA pass states it plainly — *"placement now reserves the cube's swept diameter
rather than a single frozen pose"*. `rotating_cube` has `body_envelope_m [1,1,1]` and
`sweep_envelope_m [3,3,2]`. A measured AABB is one frozen pose, so reserving it alone
lets an animated artifact swing into its neighbour. The contract now carries `sweep_m`
and the footprint takes whichever is larger.

## Correction 3: declared numbers instead of invented ones

The pilot's `wall_system` already fixes the wall bands — feature field 20–80% at
1.1–2.7 m, prop rails 0–18% / 82–100% at 0.75–2.3 m, low/eye/upper bands. Part 2 had
invented 25–75% at 0.9–2.9 m. `doc/PLACEMENT_NEGOTIATION.md` likewise declares the
overlay palette (magenta body, cyan hard, amber preferred); the diagnostics now use it.

## Correction 4: a room the kit cannot build is not a solution

`commons/data/museum_module_kit.json` and the wall kit certify pieces at 1–4 m widths
and **one 4 m height**. Part 2's ceiling raise to 9 m therefore solved the artifact's
problem by inventing architecture nobody has tested. `kit_buildable()` now reports:

```
module kit  WARN — walls are 9 m but the kit certifies 4 m pieces
```

Better a named warning than a quietly unbuildable museum. The real fix is a taller
certified piece or a different home for that artifact — a decision, not a default.

## The correction still outstanding

`spatial_floorplan.build_enfilade()` is a **parallel system** and should not survive.
The repo already holds:

- `commons/data/template_patterns.json` — ~180 authored floorplans, including 30+ real
  museum enfilades (Uffizi, Guggenheim, Castelvecchio, Dia:Beacon…) in the same
  cell-role vocabulary, plus extracted bays carrying `slots` and `hero` flags;
- `commons/data/museum_bays.json` — 144 bays from 28 museums, deduplicated, and
  measured to recompose byte-identically;
- `/template-pattern-editor`, whose own description is *"author the placement contracts
  themselves… slots (s) are where artifacts may stand"*, with a built-in walk check.

The floorplan layer should **load** one of those and expose its `s` cells as offers.
The parametric enfilade was a reasonable scaffold for proving the negotiator and is now
the wrong thing to keep. `tools/compose_map_from_dressing_rooms.py --negotiate-dry-run`
is the existing offer-generator to reuse.

Also outstanding, from the design conversation: featured artifacts should **fail rather
than default** when information is missing (the resolver currently always returns a
contract), and the 3-artifact slice should widen to the ~12 covering small, large,
wall-facing, 360°, animated, diagram and solid cases.
