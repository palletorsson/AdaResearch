# SPIKE 01 — three heterogeneous artifacts, end to end

## QUESTION

Can one negotiator place three genuinely different spatial cases into a real
museum without artifact-specific code, and can we prove the 3D result is the
plan that was approved?

## PROBE

- `bias_visualizer` — freestanding object, orbitable
- `science_screen` — wall-oriented panel
- `neural_network_visualization` — room-scale, 12.6 × 8.7 m

Later probes: `chladni_plate` (micropod lift), `you_are_here` (5-value lineage),
`lab_room` / `folding_past` / `mc_cave` (precinct), `schlegel_diagram` (caption).

## PIPELINE TRACE

Traversed: measurement → contract → brief → floorplan → slot capacity →
negotiation → wall occupancy → threshold → map compile → pathfinder →
Godot capture → correspondence gate.

**Not traversed: museum assembly.** `endless_museum.gd` never consumed the plan.
Everything 3D in this spike was rendered by a bench probe
(`commons/testing/probe_housed_artifact.gd`) using the museum's own parts.

## BASELINE

Six overlapping descriptions of an artifact's space, disagreeing on 525
artifacts. Measurements 3.5 months stale. `map_pathfinder.py check` structurally
unable to fail. No 2D↔3D check anywhere.

## CHANGES

New (all additive; `tools/placement_negotiator.py` untouched, its 10 tests green):
`spatial_contract.py`, `spatial_floorplan.py`, `spatial_negotiation.py`,
`spatial_slice.py`, `slot_capacity.py`, `exhibition_brief.py`, `wall_bands.py`,
`spatial_palette.py`, `verify_placement.py` (+ `commons/testing/verify_placement.gd`),
`gallery_walk.gd/.tscn`, `test_spatial_contract.py`.

Repaired: `measure_artifacts.gd` and `capture_dressing_room.gd` (six faults),
`text_screen.gd` (overflow + wrap ownership + Roboto), `build_museum_corpus_sheet.py`
(shared palette), caption copy on three artifacts.

## EVIDENCE

- 55 tests pass.
- Correspondence gate proven by self-test: clean map PASS, 3-cell corruption CAUGHT.
- Corpus re-measure: **878 of 1741 comparable artifacts changed (50%)**.
- 11/11 lineages routed to walls in the Uffizi vs **1/11** on the floor.
- Captures: `ada_run/spatial_slice/*.svg`, `user://housed/*.png`.

## FAILURES

**F1 — the contract does not read `spine_hints()`.**
EXPECTED: `spatial_contract.resolve()` returns every source's view of an artifact.
ACTUAL: it reads six stores and ignores `spine_hints()`, which 8 artifacts
implement and which `doc/SPINE_HINTS_CONTRACT.md` has specified since May.
CAUSE: I found the six by grepping the registry and dressing rooms; a *method*
on a scene is invisible to that search, and I never read the canonical doc.
GENERAL LESSON: a census of data files cannot find a contract expressed as code.
The ownership hierarchy has to be read, not reconstructed.
NEXT TEST: resolve `science_screen` with and without `spine_hints()` and diff —
expected `2x1 / rot 180 / y 2.0` against the current `4x1 / rot 0 / y 0.75`.

**F2 — RESOLVED, and my first diagnosis was wrong.**
EXPECTED: a headless `--shot` proving the walkable room stands up.
ACTUAL (as first recorded): watchdog killed it, no image. I attributed this to
`RenderingServer.frame_post_draw` and to `SceneTree` vs `Node3D` capture
differing. **The second of those was invented.** The real chain was three bugs:

1. A **parse error**. A patch replaced *every* occurrence of
   `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`, splicing a duplicate
   `_take_shot()` into `_input()` and orphaning the mouse-look branch. The
   script never loaded. My handoff note claimed it "loads without script
   errors"; that was false and unverified.
2. `RenderingServer.frame_post_draw` genuinely never fires under `--no-window`.
   Two process frames plus a settle works.
3. With those fixed it ran, exited 0, printed a success line, wrote a PNG —
   **and the image was an empty green field.** `_yaw = PI` was copied from
   `endless_museum.gd`, whose segments extend along +z; this room's wall is at
   z=0 with the walker at z=6, so it faced the back wall.

GENERAL LESSON: bug 3 is the one that matters. Every automated signal was
green — clean exit, success print, file written, non-zero size — and the scene
showed nothing. **A run that completes is not evidence; the picture is.** Same
lesson as the correspondence gate, reached from the opposite direction.
Corollary: do not write a cause into a spike record before reading the actual
error output. The first diagnosis here was plausible and wrong.

## DISCOVERY

1. **The corpus's floor cannot host its lineages; its walls can.** 36 series vs
   481 anchors, against 345 wall runs ≥ 4 m. This inverted the negotiator.
2. **20% of artifacts are not exhibits.** They are entered, not viewed —
   named `precinct`, routed to ground, owed a threshold rather than a plinth.
3. **Measurement was 50% wrong**, and the fix caused its own regression
   (simulations running during the settle window) that only a second reading caught.
4. **Two faults only the 3D capture could find**: off-origin geometry
   (`aabb_center`) and `name:rot:0.0` silently disabling auto-grounding.

## ARCHITECTURAL CHANGE

**No — but this spike sits in the wrong place in the canonical hierarchy, and I
only discovered that after the fact by reading `doc/SPATIAL_PIPELINE.md`.**

The top-level doctrine is intact and was followed: artifacts describe needs,
architecture describes offers, the negotiator resolves, the assembler stays
dumb, validators produce evidence.

But §4–§5 make the **dressing room** the canonical staged artifact unit, with
profiles, needs and hints used to *bootstrap a default dressing room*.
`tools/spatial_contract.py` resolves those same sources into a new dataclass and
feeds the negotiator directly, bypassing the dressing room. It should instead be
a **provider that emits default dressing rooms**. See D1 in
`doc/spatial/CURRENT_STATE.md` for the full accounting against the five
abstraction questions — it answers one of five.

This is not a doctrine change. It is this implementation being wrong about where
it belongs, recorded rather than quietly left.

**F3 — I inverted the resolution order while fixing F1, and the fix looked like a success.**
EXPECTED: wiring `spine_hints()` in would make `science_screen` resolve to its
declared `2x1 / rot 180`, per this record's own success test.
ACTUAL: it did — because I applied hints *last*, unconditionally. §4 orders them
`spine_hints() -> auto-generated room -> human-refined room`, so an **authored
dressing room outranks the scene's own hints**. `science_screen`'s author staged
it `4x1`, rotation 0 only. My patch handed the negotiator rotation 180 — a facing
the author had **excluded** — and it read as correct, because the artifact really
did ask for it.
CAUSE: I wrote the success test before reading §4, then satisfied it.
GENERAL LESSON: a success test authored by the same pass that implements it
proves consistency, not correctness. This one was checked against the doctrine
only because D1 forced a second reading of the same paragraph.
CONSEQUENCE, and it is the honest headline: **all 9 hint implementors also have
authored rooms**, so under the correct ranking `spine_hints()` changes no
footprint anywhere in the corpus today. Wiring it in was still right — it is
correct for the next artifact, and it surfaces nine scene-vs-author
disagreements that were previously invisible — but the claim is "no effect
yet", not "science_screen is now 2x1".

**F4 — `footprint` carries two units and nothing marks which.**
EXPECTED: `dressing_room.footprint` in grid cells, as `DRESSING_ROOM_SCHEMA.md`
documents and 2626 rooms honour.
ACTUAL: the 33 rooms written alongside a `placement_contract` store **metres**.
`science_screen` reads `[3.14, 0.2, 2.35]`.
WHY IT SURVIVED: read as cells it yields `[3, 1]` — a plausible number for a
3 m panel, wrong for a reason no assertion would catch. This is why `resolve()`
never consumed the room's own footprint: it could not safely.
GENERAL LESSON: the dangerous unit bug is the one whose wrong answer is
reasonable. Fractional values are the tell; the sibling key corroborates.

**F5 — a byte-identical map proved nothing, because two units met on a 1 m grid.**
EXPECTED: routing the slice through `staged()` and getting a byte-identical map
would show the seam was lossless.
ACTUAL: it showed the seam was *numerically* lossless and nothing more. The
dressing room names its clearances `front_clearance_m` / `visual_radius_m` —
**metres** — while `SpatialContract.clearance` and `.visual_radius` are
**cells**. `from_room()` coerced with `float()`. On a 1 m grid a cell count and
a metre reading are the same number, so `2` and `2.0` compared equal, the
round-trip test passed, and the map hashed identically. The floats then reached
`masks()`, where `range(1, 2.0)` raises. Two separate fields, two crashes, both
past a green suite.
CAUSE: the round-trip test asserted VALUE and not TYPE.
HOW IT SURFACED: the negative test — change an authored room, the map must move.
It crashed instead of moving. **And my first reading of that crash was wrong**:
the run died before writing the map, so the diff compared against a stale file
and I recorded "seam does NOT bite". The test now checks the run COMPLETED
before it trusts the diff.
GENERAL LESSON: this is `footprint`'s two units (F4) a second time, in a second
field, found a different way. On a 1 m grid, metres and cells are
indistinguishable by value and distinguishable only by type — so equality
assertions are structurally blind to the whole bug class here. `assertIs(type(a),
type(b))` is not pedantry in this codebase; it is the only thing watching.

## OPEN QUESTIONS

1. Should `spine_hints()` outrank the measured AABB where it disagrees, or is it
   a hint the measurement corrects? `science_screen` says `2x1`; Godot says `4x1`.
2. Where do the largest precincts (`mc_cave`, 300 m) live — generated sites, or
   out of the museum entirely?
3. Should the 33 metre-rooms be migrated to cells, or should the schema name
   both units explicitly? Migration touches authored data; the reader now
   detects it. Not decided.
4. ~~`doc/SPATIAL_PIPELINE.md` does not exist.~~ **Wrong — it exists**, 915
   lines, on `origin/palm-scanner-door-entry` (`fdbfeb8d6`, `a8b7fef18`). This
   working tree is behind origin and I concluded from a local `ls`. Read it
   before continuing: it changes the design (see D1/D2 in CURRENT_STATE).

## NEXT PROBE

D1 and D2 are closed; F1 is closed; F3 and F4 are new and closed in the same pass.

`tools/emit_dressing_room.py` now provides `staged(lookup) -> (contract, room)`:
authored room if there is one, generated default if not, and the negotiator
cannot tell which. 62 tests pass; the correspondence gate still catches a
3-cell corruption. **48 of 2708 artifacts have no room** and would be generated.

~~Next, route `spatial_slice.py` through `staged()`.~~ **DONE.** All five
contract-acquisition sites (3 in `spatial_negotiation.py`, 2 in
`spatial_slice.py`) now call `staged_contract()`; `resolve` is no longer
imported by either, so the bypass cannot return by habit. The map is
byte-identical (`a5a0d4b8`) and the gate still catches a 3-cell corruption.

The positive test was necessary and insufficient — see F5. What actually proved
the seam is the NEGATIVE test: set `bias_visualizer`'s authored rotations to
`["90"]`, and the placement moves `rotation=0 -> 90` and the map changes;
restore, and it returns to baseline. **An author editing a dressing room now
changes what the negotiator does**, which is the claim of §5 and was not true
before this pass.

Next: decide whether to write the 48 generated rooms (`--all --write`). They
are derivations, not decisions, and committing 48 files that look authored is
exactly the confusion `_generated` exists to prevent.

## FILES

`tools/spatial_{contract,floorplan,negotiation,slice,palette}.py`,
`tools/{slot_capacity,exhibition_brief,wall_bands,verify_placement}.py`,
`commons/testing/{verify_placement,probe_housed_artifact,sweep_text_screens}.gd`,
`commons/scenes/gallery_walk.{gd,tscn}`, `commons/ui/text_screen.gd`,
`doc/SPATIAL_CONTRACT_AUDIT.md`, `doc/plans/artifact_order_to_aaa_environment.md`.

## COMMITS

Uncommitted at time of writing.
