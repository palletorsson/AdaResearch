# Spatial pipeline — current state

*Fast-changing implementation state. Doctrine lives in `doc/SPATIAL_PIPELINE.md`
(915 lines, commits `fdbfeb8d6` + `a8b7fef18`) on `origin/palm-scanner-door-entry`.*

Updated 2026-08-15.

## What changed on 08-15 — rung three became the bridge-courtyard

Palle's ruling is now explicit: a broad precinct up to 40 m may stay in the
museum when the building gives it a courtyard beside a continuous bridge.
The plan owns that exception as `court_access: "bridge"`; the assembler does
not guess it from dimensions. Larger worlds still refuse and ask for a
dedicated map.

The 1 m-grid assembly now builds a 4 m bridge, a single 4 m court gate, and a
3 m walkable apron around the artifact body. The court core is deliberately
absent from the walk map. Existing centered courtyards retain their old
clamping and topology.

Full-corpus regeneration changed the negotiated result from 943 placed / 213
rejected to **1010 placed / 146 rejected**: 68 placements carry bridge access,
67 previously refused works enter, and size escalations fall from 95 to 29.
No bridge body exceeds 40 m. The remaining 28 larger precinct worlds retain
dedicated-map refusal.

The compact assembled `em_plan.json` delivery subset is a different scope: 17
museum formulas, 762 placements, 30 refusals, and 51 bridge courts. Keep those
delivery counts distinct from the 24-sequence negotiation corpus above.

Evidence:

- `test_spatial_contract.py`: 23/23.
- `test_em_plan_chapters.py`: 1/1.
- `test_em_bridge_courts.gd`: PASS (route, gate, core, apron, legacy court).
- `test_em_bays.gd`: PASS; `test_em_vr_floor.gd`: PASS (636 VR floor
  colliders, zero desktop floor colliders).
- Six-museum real-collision autopilot: PASS at z=611 m in 185.2 s. Seven
  recovery events resolved; artifact teardown still emits the existing
  freed-object/process-frame cleanup errors after the route succeeds.
- Forward capture: `ada_run/spatial_recommendation/bridge_court_dark_oak.png`.

**The refusal tail is now a build queue.**
`tools/dedicated_world_register.py` calls the same
`spatial_negotiation.requires_dedicated_map()` predicate as the negotiator and
writes `ada_run/dedicated_world_register.json`. The current 29 chapter
occurrences are 28 artifact tokens but only **21 site families**: seven alias
pairs share an actual scene and therefore one site build. Every row records the
measured full-scale body, a body-plus-3 m site envelope, its chapters and host
museums, and leaves `site_contract.formula` null. Negotiation owns why the work
leaves; architecture still owns what place receives it.

`python tools/test_dedicated_world_register.py` proves the counts, alias
collapse, full-scale envelope, stable site IDs, and the negative long-thin
case (`laser_measure` can turn, so length alone never makes it a world).
`python tools/dedicated_world_register.py --check` is the drift gate.

`ada_run/em_overrides.json` remains absent: this is a negotiated rule and a
plan/assembler capability, not a hidden hand-placement exception.

## What changed on 08-14 — the museum entered the shipped game loop

**The wide floats are verified.** The overnight plan regeneration (post
courtyard-only crossability) carries SIX balcony rows; targeted builds printed
the voice for every float asked about: `color_constellation_office` z 34..48,
`weather_vector_field` (12.4 m) z 34..51, `force_fields` z 34..44, and
`surreal_kinetic_sculpture` z 34..71 — a 37 m void built as ONE joint, just
under the 40 m cap.

**VR from the menu.** Sequences picker → pinned "∞ · Endless Museum" card →
`staging.load_scene("endless_museum_staged.tscn")`. Three blockers found, all
real, all fixed:

| | |
|---|---|
| staging contract | `XRToolsStaging.load_scene` types its scene `XRToolsSceneBase`; the old VR wrapper had a Node3D root. `endless_museum_staged.tscn` inherits `base.tscn` the way `lab.tscn` does; `em/em_staged_museum.gd` presets `_plan_path` (flagless menu launches were about to walk the UNNEGOTIATED museum). |
| floors had no body | the desktop walker CLAMPS y, so floors were meshes only — the XR rig's PlayerBody simulates gravity and fell through on frame one. Floor colliders now stamp GATED ON `_vr`: `test_em_vr_floor.gd` measures **vr=633, desktop=0** (first run read artifact-internal colliders as a leak; the claim is scoped to the segment's own Collision body). |
| null-cam crash | `_track_acoustic` read `_cam.global_position` every frame; `_cam` is null in VR. Reads `_eye_pos()` now. |

**`--em-order-file` had NEVER worked.** The flag literal is 16 chars; the parse
ran `substr(17)`, eating the path's first byte — the open failed and the pool
fell back to the full spine, silently. Found the first time anyone used the
flag; fixed, and the false exit now names which file refused.

**Second session, 08-14: the left stick, and the frame budget.**

- **"Can't move forward" was a wall the hardware finally hit.** Nothing in the
  repo touched input in the window — but `joystick_deadzone_fix.gd` has forced
  a 0.5 y-deadzone since January to mask a left stick already drifting to
  0.42 at rest. Sticks wear monotonically; when the reachable forward throw
  sank toward the wall, forward died. Replaced with CALIBRATION: the script
  samples each stick at rest at boot, writes per-tracker offsets into
  `XRToolsUserSettings.stick_rest_offsets`, and `get_adjusted_vector2`
  recentres + rescales so a stick resting at +0.42 recovers the full −1..1;
  deadzone drops to 0.2. Calibration failure falls back to the old wall
  EXACTLY. Watch the log for `JoystickCalibrate:` — rest offsets at boot and
  rolling reach per stick; ONE session gives the wear numbers. Two writers
  live on these values (this calibrator + the XR Tools settings UI/save) —
  the hidden-dependencies clause, documented in the script.
- **Render load, measured then cut** (`probe_em_render_load.gd`, 2 segments):
  3,078 mesh instances = 2,118 architecture + 960 artifact; 59 lights / 11
  shadowed (em_lighting's budget holds — lights were never the problem).
  Two changes, both desktop+VR: (1) **near-artifact rendering** — artifacts
  show < 32 m, hide > 38 m (hysteresis), never during proof shots, physics
  and hand-removals untouched; 19 of 40 hidden at spawn. (2) **box batching**
  — one MultiMesh per material per segment, unit cube scaled per instance:
  architecture instances 2,118 → 741 (+10 batch nodes), ~1,400 draw calls
  gone, doubled in stereo. Parity shot confirms the interior renders
  identically. Heaviest artifact subtrees recorded by the probe (LabRoom 146
  meshes, Matrix4x4Viewer 142 …) — per-artifact simplification is the next
  lever if needed.

**Third session, 08-14: the desktop hand.** The museum walker now mounts the
SAME crosshair interaction the map scenes prove out daily —
`DesktopInteractionPointer` (LMB press/drag on handles and buttons, RMB
carry-grab, wheel = hold distance) via a thin adapter
(`em/em_desktop_pointer.gd`) that mirrors the walker camera's transform each
frame, because the shared pointer expects a "Head"/Camera3D sibling pair the
walker doesn't have. Artifacts ship their interaction layers with their
scenes, so nothing per-artifact was wired. Crosshair dot matches
desktop_player.tscn. `test_em_desktop_hand.gd` proves both directions:
wired on desktop, ABSENT in VR (a second ray would fight the XR rig's own
pointers). Also on 08-14 (separate commit): base.tscn's ranged grab was
restored — the June capture-resave clobber had been COMMITTED in 8feb9c913,
so `git checkout` was restoring the broken rig; repaired from 8feb9c913^ and
the file is now chmod 444 like the action map.

**Fourth session, 08-14: bare hands.** "Left stick still can't move forward,
I think it's the catalyst / the interactive parts of the hand" → the honest
experiment is now one toggle away: MOVEMENT-ONLY HANDS
(`commons/scenes/bare_hands.gd`) strips all 14 hand gadgets — pickups,
pointers, gaze pointer, ghost hands, per-hand Area3Ds, message console,
wrist workstation, gravity gun, wrist stats, XP listener — from every
LOADED scene's rig (the staging menu keeps its pointers), leaving both
hands' Movement* providers, collision hands, PlayerBody and the calibrator
untouched. With FunctionPickup gone the catalyst bracelet can never attach.
**RULED DEFAULT ON by Palle the same day** (`47c30954f`): every loaded
scene's rig is movement-only; uncheck `movement_only_hands` on vr_staging
to restore the gadget rig (`--bare-hands` / the marker file remain as
force-ons). The stick CALIBRATION was stood down in the same ruling
(`calibrate = false`): the deadzone wall was live for every month movement
worked, so it is not the suspect — the input path is byte-for-byte the
January one; the calibrator and addon patch stay as opt-in.
`test_bare_hands.gd` proves strip + survival + off-mode-untouched. If
forward is STILL dead with bare hands, the gadget theory dies too — then
flip `calibrate` on and read the `JoystickCalibrate:` reach lines.

**Fifth session, 08-14: the grid wall.** Bare hands worked — Palle can move
in VR — and the next wall was literal: the rig's `PlayerBoundsCheck` ships a
10 m box around the world origin (right for grid maps), so the museum at
x 0..15 extending endlessly in +z reset the player on every walk. The
museum's VR setup now RESHAPES it rather than disabling it: x ±20, y ±10,
z unbounded — still a net under a player who escapes every catch slab.
`test_em_bounds.gd` proves it on the REAL staged scene the menu loads
(reshape landed, check still active, z=500 legal).

**Sixth session, 08-14: museum scale.** Palle walked and loved it — and the
verdict was "too small: wall-work right, passages too small, walls and
ceiling higher for a museum." Three changes:

- **One number owns the height now.** `em_detail.WALL_H` 3.0 → **4.5** is
  the single owner; em_lighting and endless_museum read it by preload (the
  old "importing would cycle" comment was wrong — em_detail imports
  nothing), and the cornice, soffit (`WALL_H + 0.14`), ceiling top, rig
  plane (`WALL_H − 0.22`) and sky plane are all arithmetic on it. Door head
  2.10 → 2.80, portal head 2.40 → 3.20.
- **Passages widen at the TILE.** `_widen_doors` converts one flanking wall
  cell of every 1-cell door to floor (straight-run flanks only — never a
  T-junction, always keeping a jamb), BEFORE anything derives, so walls,
  colliders, seals, walk cells and the door list agree. 3 doors widened in
  the first two segments; widening only opens, never closes, so walks
  strictly improve.
- **A standing figure, 1.75 m,** grey capsule canon, one per vestibule at
  (2, VESTIBULE_H/2), no collider — a ruler, not an obstacle (and not
  default_body_bay, which is an argument). Culled with the artifacts;
  probe confirms 2 figures in 2 segments.

**Seventh session, 08-14: the editable reference wall.** Palle: "editable
reference walls for all props so you know how to put." Built as three
layers, and it caught a live bug on arrival:

- **em_props' contract constants were STALE COPIES** — its own `WALL_H 3.0`,
  `SKY_Y 2.92`, `CORNICE_BOTTOM 2.72` survived the 4.5 raise untouched, so
  it would have dressed 4.5 m walls as 3.0 ones (cable tray in open air).
  All contract constants now import from em_detail/em_lighting; the
  door-relative heights (exit signs, cable tray) became the arithmetic
  their comments always claimed, so they rode the door raise for free.
- **One editable surface**: `em_props.mount_defaults()` (11 wall tokens ×
  code heights) + `commons/data/prop_wall_rules.json` (hand overrides,
  absent by default) read through `_ruled_y` at the two emitters. V1: one
  height per token — an exit_sign rule moves door AND portal signs.
- **The wall itself**: `prop_reference_wall.tscn` — every token hung at its
  resolved height on a 4.5 m wall, labels naming height and source
  (code|HAND), the 1.65 eye-line drawn, the 1.75 m figure at the end.
  WASD walk, E select, UP/DOWN nudge 5 cm, R reset, F5 saves the rules the
  museum then reads. `test_prop_wall_rules.gd`: 11 hung, hand rule
  round-trips into em_props, gate holds when the file is deleted.

**Eighth session, 08-14: the standing conventions join the wall.** "Can we
learn about all the plinths and podiums the same way?" The plinth system's
"how to put" is the VIEWING BAND (em_plinths: target_centre 1.15, band
1.05–1.30, lift 0.25–1.20) — and python's negotiator was already treating
the .gd file as its owner by regex-parsing the consts. The hand's band now
lives in `commons/data/standing_rules.json`, read by BOTH languages:
`em_plinths.band()` at build time and `spatial_contract.plinth_band()` at
plan time (file first, .gd consts second, doc literals last) — verified in
one run: hand target 1.25 → `lift_for(0.4 m body) = 1.05` in python and
the same in GDScript. The reference wall grew a BAND ZONE: five amber
handles (target/low/high/min/max) with a live translucent band stripe,
edited and saved exactly like the props; F5 writes both files. Trial: 16
records hung, both round trips, both gates. Palle's five prop rules from
his first session are committed (`c2e8b3111`). NOT covered v1: podium/
plinth structural tops (0.4/0.8 — plan-time offers would disagree until
regen; needs its own pass), ceiling/floor/edge props (no height knob).

**Ninth session, 08-14: one desktop app, in-situ prop rulings, spike 09.**
- The shipped game is now the editor suite: **TAB** toggles the curator
  editor mid-walk (records collected always, so the toggle sees every
  placement since boot); the sequences picker has a desktop-only
  **✎ Prop Corridor** card, **F10** returns. `f3741f937`.
- **In-situ prop rulings** (`d941f4fe7`): TAB, look at a wall prop,
  UP/DOWN rules the token's CONVENTION (same `prop_wall_rules.json` the
  corridor writes; every live copy previews); F5 MERGES so corridor rules
  survive; refusals for cell-move/rotate/delete with a voice. The trial
  caught that `exit_sign` is dressed at two heights — baseline is now the
  selected node's live height.
- **Spike 09** (`doc/spatial/spikes/09_…`, `a245a713d`): "the footprint
  should change the blueprint" — measured: 114 escalations = 30 bodies
  ≤12 m (need a BAY), 58 at 12–40 m (need an honest, per-length joint
  budget — the refusal text calls a cap an impossibility), 14 > 40 m
  (worlds — the >34 m tail, Palle's ruling). Three rungs proposed under
  ONE authorship rule (plan stays sole author; bays derive at build like
  `_widen_doors`). Prediction on record: rung 1 → ~84 escalations.
  **F3 retracted same session** — the "four zero bodies" were
  `artifact_sizes.json` stale entries; the contract resolves them at
  92–300 m. Fourth "measure what the code reads" of the week.

**Tenth session, 08-15: rung 1 built — and honestly inert.** `_try_bay` +
`bay_cells` + exporter `bay` + assembler `_open_bays` (`9cd1b072b`),
`test_em_bays.gd` both ways. Full regen (mtime checked — a first run was
cut by a 590 s timeout and compared the OLD plan to itself): **byte-
identical, 0 bays, 114 escalations.** Not the rung's fault: standalone
traces show five of six candidates need the ROOF opened (6–14 m tall
under 4.5 m) and the sixth wants 12 m of clear floor no template has.
The bay ships as a gated capability the corpus does not exercise. Also
found and fixed: `FloorPlan.wall_height_m` was a THIRD wall height (4.0);
`from_museum` reads em_detail.WALL_H now. And the size probe in spike 09
was corrected — `artifact_sizes.json` is a stale mirror for the WHOLE
corpus; escalations re-measured from the contract: 6 / 63 / 32, not
30 / 58 / 14. **NO SPATIAL FINDING MAY CITE artifact_sizes.json AGAIN.**

**Eleventh session, 08-15: rung 2 bites, the editor is complete.**
Rung 2 (`0e7ece96e`): the court is a rectangle you can TURN in (crossability
tests the narrow side; a body granted turned gets rotation +90 and swapped
dims, the assembler stamps the row's rotation), and the joint budget scales
with the building — clamp(0.6 × length, 40, 80), doubling once when the
queue backs up. **Measured: placed 900→943, courts 127→164, escalations
114→95, rejected 256→213.** Autopilot through the new courts PASS z 585/585
(6 unlearned) — past the z 545 stall. Remaining 95 escalations = the 32
worlds + square bodies >12 m no turn helps, now named "a WORLD, not an
exhibit — Palle's ruling" by the refusal text itself. EDITOR: SHIFT+arrows
0.2 m, PGUP/PGDN 0.2 m y, Q/R 15° (SHIFT 90°), +/- scale 5 % — all as
override rulings (`offset`, `rotation`, `scale`), all visual-only past the
cell so the seal and walk map keep the plan's footprint (`3e615b536`).

**Twelfth session, 08-15: everything stamped is movable** (`83d38d7d2`).
Three new record kinds in the same overrides file, `"kind"` field:
FURNITURE (all dressed props without a height convention; token + dress
index; arrows 1 m, SHIFT 0.2, PGUP/PGDN, Q/R), PLINTH (artifact token +
plan cell; offsets), SHOWING (hang index; offsets — pictures stay batched,
an invisible proxy is selected, the ruling shifts all 7 boxes before
emit). Applied where each is built. Two trial-caught faults: JSON int→
float broke the plinth key (typed compares); em_chapter set after the
deal left "" on plinth/prop records (set early, re-keyed on the deal's
chapter). Trial: all three ruled, saved, REBUILT at the ruling.

**NEXT: rung 3 — Palle rules the 32 worlds (walk-in precinct, or exile to
their own maps).**

**Open findings (not fixed today).**

- **Autopilot on the full plan FAILS at z 545**, inside the forces segment
  (Sainsbury false-perspective, z 479..562, its narrow end): 26 cells
  unlearned, stuck at (5.3, 545.5). Territory beyond every previous walk
  (round 2 topped out at 296 m). The forces chapter plans 96 rows into that
  narrowing — first suspect is an interior body legally sealed into the pinch.
- **The court queue grows without bound**: ≤40 m drains per joint against 15+
  courts enqueued per chapter — 39 queued by seg 3 on the full plan, 134 on a
  forces-only loop. Balconies drift many segments behind their chapters (a
  curator meets primitives' courts while walking transformation).

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
v2 (`f7621ed02`): the [ ] add-palette, chapter-scoped; adds apply at
FULL-SEGMENT parity (timing was a third author); every `_stamp` refusal now
carries a named reason — the one we chased was "sealing would sever the walk
route", and it was correct: a 7.4 m body cuts the narrowing enfilade. Trial
drives the editor's real keys and asserts on the file plus a rebuild.

**The balcony void (`ccb1b206e`).** Spike 08 fully built: the second joint
type. Side gallery walkable, 1.1 m rail with collision, floorless void with a
catch slab 4 m down, float suspended base-above-head. Crossability is now
courtyard-only (a hanging body severs no floor — it had refused
weather_vector_field from the venue built for it). Measured:
`color_constellation_office HANGS over the void at z 34..48`, and the autopilot
walked past under real physics — PASS, z 144.1/144.0, 3 cells unlearned.

**Open.** laser_measure took a 7 × 57 m court because its body still measures
50 m in Z — spike 06's config channel (**37 of 757** unreachable). The
threshold sightline (13 accepts, or **0** if `candidates[:40]` is lifted). The
>34 m tail (worlds, not exhibits) awaits its threshold ruling.

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
