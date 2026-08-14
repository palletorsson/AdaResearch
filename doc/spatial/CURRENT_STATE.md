# Spatial pipeline — current state

*Fast-changing implementation state. Doctrine lives in `doc/SPATIAL_PIPELINE.md`
(915 lines, commits `fdbfeb8d6` + `a8b7fef18`) on `origin/palm-scanner-door-entry`.*

Updated 2026-08-13.

## What changed on 08-13

Spikes 02–07 (`doc/spatial/spikes/`). Four faults closed, three found and left
open, five numbers in this file and in `HANDOVER.md` corrected.

**Closed.**

| | |
|---|---|
| the overloaded zero | `lift_for` returns `0.0` for two reasons and the support test read one. Every body over `2 × (target_centre − min_lift)` = **1.80 m** asking to be raised was refused from every floor slot *because it did not need raising*. 62 of 799 exposed, 3 realised. `fe3aa5647` |
| the 4 m offset | `_build_segment` lays a tile row at `y + VESTIBULE_H`; `_deal_from_plan` stored the raw row. Every planned object stood 4 m nearer the entrance; 30 of 281 interior rows landed in the lobby. Invisible because `_compose_auto_shot` takes its standpoint from the same displaced cell. `e9202f138` |
| `dna.fixture` unread | the harness now merges it into `artifact_config`, authored config winning. **Half-closed** — see open. `1ac266bd2` |
| 51 untracked files | tracked rulings cited evidence a clean clone did not have, including `placement_negotiator.py` and its tests, which spike 01 calls the proven foundation. `810ef88f3` |

**Placement, whole spine** — measured against the in-flight `spatial_contract.py`:

```
                     §5 baseline   after aliases   after the zero
placed                       678            769             803
interior                     383            429             440
                          33.13%          37.1%           38.1%
rejected                     478            387             353
support_matches_contract     205             18               3
chapters fully housed       0/24           0/24            0/24
```

The 3 survivors are legitimate (`science_screen` ×2, `lambda_slider` — all need a
wall, offered slots with none). **The support bottleneck of §7.2 is spent.** Top
refusals are now `escalation` 189 and `physical_overlap` 107.

**Corrections to numbers this file and HANDOVER carry.**

- `props_per_10m` **has** had a supplier since the white-cube pass
  (`em_budget.gd:450` → `em_props.gd:449`). §8 quotes a past-tense before-state.
- the module kit's **11.7×** mixes denominators — per dressed metre against per
  wall cell. True factor **8.68×**.
- mean unbroken wall run is **2.41 m pooled**, not 2.7 (a mean of 30 per-building
  means, quoted beside three pooled figures).
- `dna.axes` is on **757** artifacts, not the 184 CLAUDE.md claims.
- `28 of 30` museums in the threshold work is two denominators, not an error.

**Assembler faults: closed 08-13 (second session).** Rotation reaches the scene
with the grid's sign (`cc600fc3f`, 61 of 507 rows turn, 72.4% of pixels move in a
controlled same-camera pair); the dealing cursor advances a CHAPTER per planned
segment (`d0aec8ad4`, before: sainsbury x3, after: sainsbury / uffizi /
grande-galerie); the banner names its chapter (`9a88d3196`,
`chapter=primitives / transformation / symmetry`). `--em-plan --em-segments=N`
is now a corridor that walks the curriculum in order and says so.

**The exporter key: closed (third session, 08-13).** `plans: [{museum,
sequence, ...}]`, one row per chapter, displaced included; reader resolves
chapter-first with the v1 dict as fallback (`1973ef77c`). NT1 failed v1 with
`change -> grande-galerie: plan holds 'symmetry'` and passes v2. Live: seven
segments, grande-galerie serves symmetry@2 AND change@5 with its own cast —
buildings shared over time.

**The courtyard: built v1 (spike 08, `eb986bd6a`).** Precinct venue derived in
the contract (float -> balcony, grounded -> courtyard, provenance each);
negotiator grants court_m = body + 3 m aprons; 261 court rows in the plan
(planned rows 507 -> 975); assembler chains unroofed courts with 1.1 m parapets
after the tile, apron derived by sealing. Gated: court-free plan builds
identically (0.022% vs 1.020% noise floor). lab_room stands in a walled court
under the museum's first open sky.

**Court walkability: walker-proven (`e0ceddc46`).** Round 1 stalled at z=133
inside dome's clamped court (26 cells unlearned, exit 1); the negotiator now
refuses any body wider than tile_w − 3 (FloorPlan carries its apron so the rung
can know), 136 uncrossable courts fell back to open ground (261 → 125 rows), and
round 2 walked the building plus ten courts to the goal centimetre — ok:true,
z 296.04/296.0, **2** cells unlearned, exit 0.

**Courts distributed (`7e839b274`).** A queue drains ≤ 40 m of court per joint,
deep courts standing alone; measured rhythm 34-25-…-57-…-25-…-93. Distribution
exposed the last two-clocks fault: the rotation chose capuchin for
transformation while the plan held the Uffizi — the plan now OWNS the building
(`_plan_owner`, plan → crown → rotation), all segments plan-stamped in the
plan's buildings. Autopilot round 3: ok, z 150.06/150.0, **1** cell unlearned.

**The curator's hand (`3c587a64f`).** In-museum editor under `--em-edit`:
E/arrows/Q/R/DEL/F5 write `ada_run/em_overrides.json` — rulings keyed
(chapter, token, from-cell), never scene transforms. Applied over the plan,
each application printed, idle overrides reported. Round trip proven headless.

**Open.** The balcony void is designed, unbuilt (rows
still count "exterior"). laser_measure took a 7 × 57 m court because its body
still measures 50 m in Z — spike 06's config channel (**37 of 757**
unreachable). The threshold sightline (13 accepts, or **0** if
`candidates[:40]` is lifted).

> **A method note worth more than any of the above.** Three times on 08-13 a
> session diagnosed the WORKING TREE instead of `HEAD` and was wrong — once
> after quoting this file's own correction about it. `doc/plans/capture_measure_faults.md`
> is a whole document retracted for it: five of its six faults had been repaired
> the day before in `549f83e23`. Reading the warning is not running the command.
> `git show HEAD:<path>` belongs in the loop.


> **Correction.** An earlier version of this file said `doc/SPATIAL_PIPELINE.md`
> "does not exist yet". It does. It was never missing — **this working tree is
> behind origin**, and the conclusion came from a local `ls` without checking
> git or the remote. That is the doctrine's own first point: the repository is
> the durable memory, not the working tree. `git show a8b7fef18:doc/SPATIAL_PIPELINE.md`.

## Where the pipeline actually runs today

```
artifact -> dressing room -> brief -> floorplan -> negotiation -> wall/floor -> capture
   ok          ok            ok        ok           ok            ok          ok
```

| layer | state | entry point |
|---|---|---|
| Measurement | repaired, corpus re-measured | `commons/testing/measure_artifacts.gd` |
| Staged unit | **the dressing room**; 48 defaults generated | `tools/emit_dressing_room.py::staged` |
| Contract | provider into the room, reads `spine_hints()` | `tools/spatial_contract.py` |
| Brief (order + lineage) | works | `tools/exhibition_brief.py` |
| Floorplan | loads the 30 authored museums | `tools/spatial_floorplan.py::from_museum` |
| Slot capacity | precomputed, 475 slots | `tools/slot_capacity.py` |
| Negotiation | match-first, then search | `tools/spatial_negotiation.py` |
| Wall domain | runs + lineage rows | `spatial_negotiation.hang_run` |
| Threshold | door + sightline + caption | `spatial_negotiation.threshold` |
| Validation | 2D↔3D correspondence gate | `tools/verify_placement.py` |
| Assembly | **NOT wired** — see Open questions | `commons/scenes/endless_museum.gd` |

Tests: `python -m unittest discover -s tools -p "test_*.py"` — 63 pass.
Gate: `python tools/verify_placement.py --self-test` — clean map PASS, corruption CAUGHT.

## Numbers worth not re-deriving

- Registry: 2708 artifacts; **2172 exhibited, 536 precinct** (20%).
- Dressing rooms: 2660 authored + **48 generated** = 2708, one per artifact.
  34 authored carry a `placement_contract`; 33 of those store `footprint` in
  METRES where the other 2626 use cells.
- Measurement: 1752 → 2647 measured; **878 changed (50% of comparable)**;
  14 withheld as unstable (simulations that walk during the settle window).
- Floor vs wall supply: **36 floor-slot series** for **481 anchors** declaring a
  DNA run, and 18 of 30 museums have none — against **345 wall runs ≥ 4 m** in
  27 of 30. Lineages are a wall proposition.
- Slot capacity: 475 slots, 312 wall-backed, 36 series.

## Where this implementation diverges from the canonical pipeline

Measured against `doc/SPATIAL_PIPELINE.md` §3–§5 **after** the code was written.
Two divergences. **Both are now closed** — see "How D1 and D2 were closed" below.
The statements of the divergences are kept as written, because the reasoning that
found them is worth more than a tidy page.

**D1 — the canonical staged unit is the DRESSING ROOM, not a contract object.**
The doctrine's flow is `ATLAS/SEQUENCE -> DRESSING ROOM -> COMPOSER/NEGOTIATOR`,
with profiles, needs and hints used to **bootstrap** a *default dressing room*
(§4 "auto-generated default dressing room"; §5 "Use profiles and hints to
bootstrap them"). `tools/spatial_contract.py` instead resolves those sources
into a new `SpatialContract` dataclass and hands that straight to the
negotiator, bypassing the dressing room.

The resolution logic and per-field provenance are what bootstrapping needs —
but they are in the wrong role. The contract should be a **provider that emits
default dressing rooms**, and the negotiator should consume dressing rooms.
Only 34 of 2659 dressing rooms carry a `placement_contract`; the correct
response to that sparsity was to *generate the other 2600 defaults*, not to
build a parallel canonical unit beside them.

Against the five questions an abstraction must answer: the dressing room
already owns this information; it is strictly more expressive (micro-layout,
plinth, label, light, legal rotations); the new concept should have been a
provider, not a canonical representation; it supersedes nothing intentionally;
and no migration was designed. That is four answers short.

**D2 — `spine_hints()` is skipped.** §3 calls it "a provider into the spatial
contract" and §4 places it in the resolution order. The resolver never reads it.
See gap 1 below.

## How D1 and D2 were closed — 2026-08-12

**D2.** `commons/testing/dump_spine_hints.gd` **calls** `spine_hints()` on every
artifact (§3 defines it as dynamic, so parsing the literal would be a static
answer to a question the doctrine says is not) and writes
`ada_run/spine_hints.json`. 2653 artifacts checked, **9 implement it** — not the
8 this file claimed. `spatial_contract.spine_hints_index()` reads it.

**D1.** `tools/emit_dressing_room.py`. `build()` emits a default dressing room in
the canonical schema; `from_room()` reads one back as the contract the negotiator
consumes; `staged(lookup)` is the entry point and returns the authored room if
there is one, the generated default if not. The dataclass is now a **view over**
the dressing room rather than a rival to it. Authored rooms are never
overwritten, and every generated room carries a `_generated` block naming its
sources — a reader can tell a derivation from a decision.

Proof the room is genuinely canonical: the negotiator and the mask builder read
13 fields; a round-trip test asserts all 13 survive
`resolve -> build -> from_room` for 7 heterogeneous artifacts. Four of the 13
were not named anywhere in the schema and had to be added, which is the test
doing its job — a room that cannot be negotiated from is documentation.

**The 48 missing rooms are written.** `--all --write` generated 48 files and
left 2660 authored ones untouched. Every generated file carries `_generated`
(author, sources, conflicts, timestamp), so a reader can tell a derivation from
a decision, and the generator will skip any file once that block is removed.

Writing them found a bug in the generator: width and depth were derived with
`ceil` and **height with `round`**, so a 1.42 m cabinet declared 1 cell of
headroom. **33 of the 48 were short.** Now ceil throughout, with a test
asserting the declared height covers the measured body.

Two of the 48 are worth a human eye rather than a fix: `museum_wall_kit_atlas`
measures 28.5 x 24.5 m (correctly `precinct` — it is an atlas of the whole wall
kit, entered rather than viewed), and three cabinets that measure genuinely
sub-metre land at 1x1. All four are real measurements, none `withheld`.

**The pipeline is routed onto it.** All five contract-acquisition sites — three
in `spatial_negotiation.py`, two in `spatial_slice.py` — call
`staged_contract()`. Neither module imports `resolve` any more, so the bypass
cannot come back by habit. `Museum_Spatial_Slice` compiles byte-identical
(`a5a0d4b8`), and the negative test moves it: set `bias_visualizer`'s authored
rotations to `["90"]` and the placement goes `rotation=0 -> 90`; restore and it
returns. **An author editing a dressing room now changes what the negotiator
does.** That was the point of §5 and it was not true before.

### Two faults this closing found

**The ranking was inverted, and the inversion looked like a success.** §4 orders
`spine_hints() -> auto-generated room -> human-refined room`, so **an authored
dressing room outranks the scene's own hints**. D2's first patch applied hints
last, unconditionally, which handed the negotiator rotation 180 for
`science_screen` — a facing its author had *excluded*. It read as correct
because the artifact really did ask for it.

The consequence is the honest headline: **all 9 hint implementors also have
authored rooms**, so under the correct ranking `spine_hints()` changes no
footprint anywhere in the corpus today. Wiring it in was still right — it is
correct for the next artifact, and it now records 9 scene-vs-author
disagreements that were previously invisible — but the claim is "no effect yet",
not "science_screen is now 2x1". Gap 1 below overstates the damage: those 9
artifacts were not being staged wrongly; their authors had already decided.

**Two units in one field, twice more — and a 1 m grid hides it.** The dressing
room names clearances `front_clearance_m` and `visual_radius_m`; the contract
holds both in **cells**. `from_room()` coerced with `float()`, and because a
cell count and a metre reading are the same number at this scale, `2` and `2.0`
compared equal, the round-trip test passed, and the slice produced a
byte-identical map. The floats then reached `masks()`, where `range(1, 2.0)`
raises. **The round-trip test asserted value, not type** — and on this grid
equality is structurally blind to the entire bug class. It now asserts both.

A byte-identical map is therefore a *necessary* result and not a sufficient one.
Only the negative test — change an authored value, the map must move —
distinguishes a working seam from an inert one.

**`footprint` carries two units.** The schema documents grid cells and 2626 rooms
honour it; the 33 rooms written alongside a `placement_contract` store **metres**
(`science_screen`: `[3.14, 0.2, 2.35]`). Nothing marks which. Read as cells it
gives `[3, 1]` — plausible for a 3 m panel, wrong for a reason no assertion would
catch, and the reason `resolve()` never consumed the room's own footprint.
`from_room()` now detects it; the 33 files are **not** migrated, because that
edits authored data and is a decision, not a derivation.

## Known gaps, in priority order

1. ~~**The contract does not read `spine_hints()`.**~~ **CLOSED 2026-08-12** —
   and the count was wrong (9, not 8), and the conclusion was too strong: the
   authored dressing room outranks the hint, so those artifacts were not
   mis-staged. See "How D1 and D2 were closed" above. Original text follows.

   Eight artifacts implement it
   (`commons/grid/SpineHints.gd`, `doc/SPINE_HINTS_CONTRACT.md`, May 2026) and
   it sits in the ownership hierarchy between `spatial_needs` and the dressing
   room. On `science_screen` it declares `footprint 2x1`, `rotation_y 180`,
   `height 2.0` while `tools/spatial_contract.py` resolved `4x1` and rotation 0
   from the measured AABB and the dressing room. **The contract layer is wrong
   for those eight artifacts and nothing currently detects it.**
2. **The assembler is unwired.** `endless_museum.gd::_deal_segment` still deals
   its own artifacts; `_stamp` carries position only — no rotation, no mount, no
   y-offset. Everything upstream produces a plan nothing consumes.
3. **The certified wall kit has zero placements** across 2417 maps.
4. `mc_cave` (300 x 300 m) and the largest precincts have no site; a 14-cell
   apron is not a landscape.
5. `build_wall_faces.py`'s frieze stops at 3.2 m on a 4 m certified wall —
   0.8 m unexplained. `python tools/wall_bands.py --check` reports it.

## Data ownership, as built

```
measured AABB (measurements.aabb_size)      geometry — Godot wins
  -> spatial_profile                        derived
  -> registry spatial_needs                 broad, part-manual
  -> spine_hints()                          NOT READ — gap 1
  -> dressing room placement_contract       hand-authored intent
  -> negotiator                             resolves, never authors
  -> architecture                            offers, never excepts
```

`tools/spatial_contract.py` is a **read layer**: it writes nothing back, and
every field carries provenance naming its source.

## Commands

```bash
python tools/spatial_contract.py --artifact=science_screen --masks
python tools/exhibition_brief.py --count=12 --museum=uffizi-spine-enfilade
python tools/slot_capacity.py
python tools/spatial_slice.py --museum=grande-galerie-axial
python tools/verify_placement.py --map=Museum_Spatial_Slice --self-test
python tools/wall_bands.py --check
python tools/spatial_palette.py --check
```
