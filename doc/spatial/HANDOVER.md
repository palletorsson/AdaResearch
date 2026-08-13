# Handover — the spatial pass, 2026-08-11 → 08-13

*You are picking up a pipeline that now runs end to end: an artifact's own
declaration reaches a walkable museum, and every stage of it has been
photographed. This document is what I wish I had been handed.*

**Images: <http://localhost:3003/spatial-iterations>** — ten iterations, every
stage before and after, each stamped with the numbers that were true when it
ran. Read them in order; the sequence is the argument.

---

## 1. What the thing is

```
artifact
  └─ dressing room ......... the canonical staged unit  (tools/emit_dressing_room.py)
       └─ exhibition brief .. order + kinship, no coordinates
            └─ floorplan .... an authored museum as slots  (tools/spatial_floorplan.py)
                 └─ negotiation ... which slot, which rotation  (tools/spatial_negotiation.py)
                      ├─ map_data.json ....... the GRID world   (tools/spatial_slice.py)
                      └─ em_plan.json ........ the MUSEUM world (tools/export_museum_plan.py)
                           └─ endless_museum.gd --em-plan
                                └─ capture → tools/publish_iteration.py
```

**One negotiator, two renderers.** That is the load-bearing fact. `GridSystem`
builds `map_data.json` maps (2049 of them, the teaching spaces).
`endless_museum.gd` builds segments from `template_patterns.json` tiles — its
own builder, one `GridSystem` reference in 123k of source. The negotiator
compiles to both.

**Settled by the user, 08-13:** keep both. The grid is the abstract
representation; the endless modular museum is the final work. They may keep
their own ceilings (§6). What must never fork is the negotiator — the moment
there are two, the two worlds start lying to each other.

**"The AAA museum" is not a third space.** It is the modular space with the
placement decision moved upstream. Wiring it was ~120 lines, not a renderer.

---

## 2. Read these first, in this order

| file | why |
|---|---|
| `doc/SPATIAL_PIPELINE.md` | The doctrine. 915 lines. **Read before proposing any abstraction.** §4 is the resolution order and §5 is why dressing rooms are central. |
| `doc/spatial/CURRENT_STATE.md` | Fast-changing state, the divergences D1/D2 and how they closed |
| `doc/spatial/spikes/01_three_artifacts_through_the_pipeline.md` | The failure record. F1–F5. Read the failures, not the successes. |
| `doc/reports/interior_bottleneck.json` | Why "only 179 of 1456 interior" was a question about my own arithmetic |
| `doc/reports/order_to_walk.md` | The curriculum survives the pool and dies in the architecture |
| `doc/reports/museum_modularity.md` | Why the certified module kit should stay orphaned |
| `doc/reports/ceiling_convergence.md` | Two ceilings, and why that is correct |

---

## 3. The tools, and what each one owns

**Resolution and staging**

- `tools/emit_dressing_room.py` — **the entry point.** `staged(lookup)` returns
  `(contract, room)`: the authored dressing room if one exists, a generated
  default if not, and the negotiator cannot tell which. `build()` writes a
  default; `from_room()` reads one back. 2660 authored + 48 generated = one per
  artifact. Generated files carry `_generated`; the generator skips any file
  once that block is removed.
- `tools/spatial_contract.py` — the resolver behind it. Reads six stores with
  per-field provenance, writes nothing back. `resolve()` is *not* the pipeline
  entry point; `staged_contract()` is.

**Architecture and placement**

- `tools/spatial_floorplan.py::from_museum(key)` — an authored museum as a
  `FloorPlan`. **Interior slots come only from `commons/data/slot_capacity.json`**,
  which covers the 30 real museums. A template absent from it gets a plan with
  zero slots, silently.
- `tools/slot_capacity.py` — 475 slots, per-rotation capacity. Regenerate after
  editing tiles.
- `tools/spatial_negotiation.py` — `rank_slots` (match/searched/exterior),
  `try_place`, `negotiate`, `hang_run` (lineages → walls), `threshold`.
- `tools/exhibition_brief.py` — order and kinship, no coordinates.

**Output and evidence**

- `tools/export_museum_plan.py` → `ada_run/em_plan.json`. Filters on the
  `museum` field (§5).
- `tools/museum_wizard.py` + `/museum-wizard` — the pipeline as 8 steps that
  each show their state. Sibling to `/map-wizard`, not an upgrade of it.
- `tools/verify_placement.py --self-test` — the 2D↔3D correspondence gate.
  Clean map PASS, 3-cell corruption CAUGHT. **Run this after touching anything.**
- `tools/publish_iteration.py` — captures → `/spatial-iterations`. **Images
  belong in the encyclopedia, reports in the repo.**
- `tools/pipeline_images.py` — before/after for threshold, lineage, precinct, gate.

**Measurement**

- `commons/testing/measure_artifacts.gd` — fixed 08-13 (§7). 
- `commons/testing/dump_spine_hints.gd` — calls `spine_hints()` on every
  artifact. It must be **called**, not parsed; the doctrine defines it as dynamic.
- `commons/testing/em_ceiling_probe.gd` — swaps a ceiling inside the museum's
  own shutter window without editing a shipped file. A good pattern to copy.

---

## 4. Running it

```bash
python tools/export_museum_plan.py --all --limit=8      # negotiate into the 30
python tools/verify_placement.py --self-test            # the gate
python -m unittest discover -s tools -p "test_*.py"     # 63 tests
```

```bash
python tools/godot_watchdog.py --expect="<png>" -- "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off --no-window commons/scenes/endless_museum.tscn -- --em-plan --em-first=uffizi-spine-enfilade --em-shot=user://proof.png --em-segments=2
```

### Traps that cost real time

- **`--headless` disables the renderer.** Use `--xr-mode off --no-window`. A run
  that exits 0 having written no PNG is the default failure here.
- **`--em-segments=N` is inert without `--em-shot`.** `_ready()` reads
  `preload_n` only when a shot path is set.
- **Godot rotates its log at boot**, so finding it by newest mtime returns the
  *previous* run. `godot.log` is the run that just finished.
- **One Godot at a time.** The second dies silently on the `user://` lock.
- **`_compose_auto_shot` picks its standpoint from what was dealt**, so changing
  a plan *moves the camera*. Every before/after pair in the gallery inherits
  this caveat. It is not a controlled comparison by construction.
- **Something stages artifact files into whatever commit runs next.** Stage,
  then run `git diff --cached --name-only` **as its own command**, then
  `git restore --staged` anything that is not yours, then commit. Never chain
  `add && commit` — I did, three times, and three of my commits carry another
  session's artifacts.

---

## 5. Numbers you should not re-derive

| | |
|---|---|
| artifacts | 2708; **2172 exhibited, 536 precinct (20%)** |
| dressing rooms | 2660 authored + 48 generated |
| templates | 182 keys, of which **30 are real museums** — the rest are brushes |
| slots | 475 across the 30; largest single slot capacity varies 12–42 cells |
| interior placement, 8-artifact sample | 179 of 240 = 74.6%, then 78.8% after the route fix |
| **interior placement, WHOLE SPINE** | **383 of 1156 = 33.13%**. 678 placed, 478 refused, **0 of 24 chapters fully housed** |
| why it cannot be housed | **457 of 1156 (39.5%) cannot stand in ANY museum before capacity is consulted** — 260 precinct-sized, 198 declaring a support word no slot speaks (`platform` 120, `none` 29, `float` 23). Floor running out is only 67 of 478 refusals |
| walls | 5071 m across 2104 walls; **91.4% of band area already bare**; mean unbroken run 2.7 m; **59% of walls are exactly 1 m** |
| wall runs ≥4 m | 55.1% of cells; **all 30 museums can host a 4 m panel** |
| mis-measured by root scale | **37** artifacts |

**`bay:<name>#bN` tiles PARTITION their parent.** `altes-rotunda-hub` has 15
slot tokens; its two bays have 13 + 2 = the same 15. Planning both double-counts.
`lattice:`/`beat:` keys are wallpaper courses. Filter on the `museum` field, as
`endless_museum.gd:548` and `validate_museum_templates.py` do.

---

## 6. Rulings — decided, do not re-litigate without new evidence

**A plinth is furniture, not a tile.** `em_plinths.gd` stands plinths on floor
cells and computes lift as `TARGET_CENTRE - h/2 - cell.top`, subtracting the
riser the template built. A floor slot is not a refusal; it is a taller plinth.
Removed 315 rejections.

**One authored rotation is a preference; two or more is a constraint.** An
author who lists three has considered the fourth. The authored value leads and
every turn away from it is recorded on the placement.

**The body is the hard route test, clearance is the soft one.** Nothing walks
through an object; a through-route and a viewing apron may be the same floor.

**Access needs somewhere to STAND, not a clear apron.** Zero open cells refuses;
a partial band places and pays in the score.

**The measurement wins on body size; the room wins on intent.** Rotations,
modes, faces are authorship. Extents are geometry.

**Depth before rank.** Measured across all 30 templates: walk-order tau
+0.05 → +0.76, leads-only +0.10 → **+1.000 with zero inversions in 225 lead
pairs**, and **museums opening at the back wall 14/30 → 0**. It costs hero
placement — leads on hero cells 30 → 4 — which a 3-template sample understated.
Rank is a property of the furniture; depth is a property
of the encounter. A walker cannot see a plinth's rank until they are in front
of it. Both `em_sets._slot_before` and `_build_segment`'s slot sort use
`(y, rank, x)` — **they must agree**, or leads are selected from one cell and
placed in another.

**The module kit stays orphaned.** `commons/data/museum_module_kit.json` is
complete and certified — and its own profile is 11.7 draw nodes per linear
metre against the museum's 1.0. Wiring it in makes the building 11.7× heavier.
It was certified on a 128 m bench, never against a real 228-cell segment.

**The two ceilings stay separate.** `GridCeilingComponent` is a sealed service
plenum that owns its lights (0.5 m module, 4.0 m soffit); `em_detail`'s is a
roof, 18.3% open, through which `em_lighting` reaches the floor. Opposite
intent. Adopting either costs 1252× the nodes and breaks `em_props`, which pins
vents to the middle of a solid panel.

---

## 7. Open, in the order I would take them

1. ~~The cast~~ **DONE.** Calling `museum_wizard.stage_brief` instead of a flat
   prefix: **240 placed / 189 interior → 450 / 344** corpus-wide (+87.5%/+82.0%).
2. ~~The spine run~~ **DONE** (`tools/spine_run.py`, `doc/reports/spine_run.md`).
   **The support vocabulary is the bottleneck, not floor area** — see §5. Fixing
   `none` alone (29 bodies refused everywhere by what looks like a plain defect
   in `spatial_negotiation.py`'s support match) is the cheapest next win.
   Then `platform`, at 120 bodies the largest single class.
3. **A third loss channel, uncounted until captured:** 98 planned interior → 18
   "not in pool" → **15 more vanish SILENTLY inside `_stamp()`** → 65 objects
   actually in rooms. The plan is not what the walker meets.
4. **Seven chapters have a plan no building can receive.** `em_plan.json` is
   keyed by BUILDING; the crown/rotation gives 24 chapters 17 distinct buildings.
3. **The root-scale re-measure** — `doc/reports/root_scale_remeasure.json` is a
   **proposal, not applied**. 37 artifacts; 24 change their oriented `[w,d]`;
   22 change slot acceptance. `CoordinateSystem3M` goes 5×4 → 8×6 cells and
   from 71 to 7 hostable slots, across 43 maps — while `sync_footprints.py`
   reports nothing, because both sides exceed its cap of 9. Six others hide the
   same way.
4. **The threshold sightline fault** — `threshold()` proves the line crosses the
   wall only at the door, but a line crossing *no* wall passes too. **22 of 28
   museums certify a door the sightline never touches.** The one-line assertion
   would turn 22 accepts into rejects, so the standing point needs deciding first.
5. **Two flips that are the user's:** which buildings declare `white_cube`
   (currently **0 of 182**, so the paint works and reaches nobody), and whether
   `--em-wall-runs` becomes default-on (7.29× lighter, pixel-identical).
6. **9 unmeasurable artifacts** — 4 call `randf` during build (seed export +
   `dna.fixture` fixes them); 5 have no RNG and are simply elsewhere when the
   shutter opens. And **159 artifacts record `aabb_size: [0,0,0]`** with nothing
   marking them: the fallback flag exists in the code and appears on 0 of 2644
   registry blocks.
7. **`em_props` has no sprinklers, smoke detectors or speakers**, which the grid
   system does. Answer it in `em_props`' idiom, not by adopting the grid ceiling.

---

## 8. How to work here

This is the part I would actually want handed to me.

**Write the number down before you measure it.** Every real finding in this pass
came from a prediction that disagreed with a measurement. Mine that were wrong:
"eleven museums are losing a resident" (it was one), "736 interior slots sit
idle" (measured across brushes with no slots), "182 museum templates" (30),
"`gallery_white()` has zero callers" (it is reached reflectively, so grep finds
nothing), "every metre-room agrees to two decimals" (16 of 34), "the 1% rule
will separate stable from unstable" (below 1 m a single 0.01 snap step exceeds
1%), "11/11 lineages on walls" (8/11), "/map-wizard has 8 steps" (13).

A prediction that agrees with the measurement is worth little. One that
disagrees is worth the whole pass.

**A run that exits 0 is not evidence; the picture is.** This project has
published a stale frame — clean exit, success print, non-zero file, and an
image from seven hours earlier. Check mtimes.

**Measure the noise floor before you believe a delta.** The same map captured
twice, unchanged, differs by 1.020% because the biome reseeds — against 2.556%
for a real 3.50 m fault. Only 2.5×. That is why the gate measures metres.

**A flat number can be a fact about where the camera stood.** A ceiling swap
measured 1.116 from the museum's composed camera and 1.769 from a standpoint
that looks up. Same swap, same seed, 6× disagreement. This is the anamorphic
lesson from the DNA work arriving independently in the museum.

**Two places holding one number is this codebase's endemic bug.** Every
significant defect in this pass was a version of it: `footprint` in metres in 33
rooms and cells in 2626; `front_clearance_m` named metres and held as cells; a
slot's *pocket* versus its *capacity*; the dressed-face count versus
`_perimeter_of(tile)`, both called "wall run"; root-local versus world in the
AABB. **On a 1 m grid, metres and cells are the same number** — so equality
assertions are structurally blind to the whole class. Assert types too.

**Prefer turning a knob to adding a system.** The white cube needed four
existing knobs, one of which (`props_per_10m`) had been read by `em_props`
since it was written and *never supplied by anything*.

**Additive and gated.** A building without the new data must be untouched, and
the gate needs a negative test proving it bites.

**Record the retraction.** Several commits here exist mainly to correct an
earlier commit's claim. That is the point. `6ed9c0916` taught a rule using an
example that turned out to be a measurement bug; the rule may still be right,
and the commit that fixed the measurement says so.

---

## 9. Where the pictures are

`http://localhost:3003/spatial-iterations` — newest first:

1. the museum built from wall runs, not 1 m cubes
2. two ceilings: why the grid's does not belong in the museum
3. the whole pipeline: threshold · lineage runs · precinct · the gate
4. the museum wizard, proved on uffizi-spine-enfilade
5. walk order: the chapter no longer opens at the back wall
6. the white cube: emptier walls, and the paint that reaches nobody
7. the measurement wins on body size
8. one authored rotation is a preference
9. a plinth is furniture, not a tile
10. endless_museum consumes the negotiated plan

Publish the next one with:

```bash
python tools/publish_iteration.py --label="what you tried" --from=<dir> --note="<the numbers>"
```

The gallery computes deltas between consecutive runs and scores `rejected` as
lower-is-better, so the arrows do not congratulate a regression.
