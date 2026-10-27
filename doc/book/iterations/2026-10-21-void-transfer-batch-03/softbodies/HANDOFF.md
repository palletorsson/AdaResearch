# Soft Bodies → Void transfer: HANDOFF

**Current status:** integrated and validated by Codex; 63 native and 15 editor checks pass. Physical headset and curation remain pending. See coordinator acceptance below.

## Original Claude handoff (before coordinator validation)

Owner: Claude Opus. Written 2026-10-21. Batch: `doc/void-transfer/2026-10-21-batch-03/`.
Stage: **placed**. Native-tested: no. Headset-tested: no. Curated: no. No Godot run.
`python tools/audit_void_transfer.py softbodies` passes 76 / 76.

**Merge first:** three catalog `scene` overrides in `catalog-additions.json` are required.
Without them the deformation and cloth consoles build nothing, and the mill sphere and
the four stop bodies end up on the canopy.

## Files (all in `commons/void/trials/softbodies/`)

| file | what |
|---|---|
| `rooms.json` | 7 + 5 original placements, 14 provenance floor captions |
| `soft_workshop_void.gd` / `.tscn` | console adapter: binds partners from the floor's mounts, then the original desk code |
| `void_soft_body.gd` | `softbody3d.gd` subclass: its two height guards made floor-relative |
| `softmill_void.tscn` | inherited `softmill.tscn`; only `SphereSoftBody08.script` changes |
| `softbodybody_void.tscn` | inherited `softbodybody.tscn`; only `SphereSoftBody.script` changes |
| `fourstopsoftbody_void.tscn` | inherited `fourstopsoftbody.tscn`; only `soft_body_scene_path` changes |
| `catalog-additions.json` | 3 required scene overrides, 1 optional pre-ready flag, 2 optional footprints |
| `source-inventory.json` | each placement `placed` with its `void` record; `transfer` block |
| `transfer-status.json`, `HANDOFF.md` | this package |

`layout.json` and `trial.tscn` are the scaffold, unchanged (six-metre storeys suffice:
the tallest bodies are the 3.8 m straps and 3.25 m mill). No original source, text,
shared file or earlier trial folder was touched. No git operations.

## Placement

Each floor is its source grid turned 180° about a chosen centre, 1 cell = 1 m:
`void_x = cx - cell_x`, `void_z = cz - cell_z`, `facing = token_rotation + 180`.
Deformation uses cx 15, cz 12; Cloth uses cx 16, cz 15. The centres were chosen so
every body clears both shaft holes and the A landings. The entrance row lands at or
beside the shared spawn (0, 12), so the visitor meets each console first, buttons
toward them, as in the museum. Heights follow the museum plan rows.

| rooms id | source cell, token | void x, z | facing | height | scale |
|---|---|---|---|---|---|
| `f1_science_screen_4_5` | (4,5) `science_screen:180:1.5#mode:field` | 11, 7 | 0 | 1.5 | 1 |
| `f1_soft_workshop_console_11_5` | (11,5) `soft_workshop_console:180#chapter:deformation` | 4, 7 | 0 | 0 | 1 |
| `f1_jelly_cube_8_8` | (8,8) `jelly_cube:180:1.0#anchor:crown` | 7, 4 | 0 | 1.0 | 1 |
| `f1_softmill_19_12` | (19,12) `softmill` | -4, 0 | 180 | 0 | 1 |
| `f1_jelly_variants_8_16` | (8,16) `jelly_variants` | 7, -4 | 180 | 0 | 1 |
| `f1_film_jelly_skin_1_19` | (1,19) `film_jelly_skin:90:0#plinth:0#pin:true` | 14, -7 | 270 | 0 | 1 |
| `f1_radiolaria_18_22` | (18,22) `radiolaria:0:0:0.5` | -3, -10 | 180 | **0.45** | 0.5 |
| `f2_soft_workshop_console_11_5` | (11,5) `soft_workshop_console:180#chapter:cloth` | 5, 10 | 0 | 0 | 1 |
| `f2_cloth_straps_8_10` | (8,10) `cloth_straps#lesson:true` | 8, 5 | 180 | 0 | 1 |
| `f2_softstopscene_18_12` | (18,12) `softstopscene#landing:rail` | -2, 3 | 180 | 0 | 1 |
| `f2_film_cloth_relations_1_27` | (1,27) `film_cloth_relations:90:0#plinth:0#pin:true` | 15, -12 | 270 | 0 | 1 |
| `f2_tension_membrane_15_57` | (15,57) `tension_membrane:180:0#plinth:0#pin:1` | 1, **-9.5** | 0 | 0 | 1 |

Configs are the tokens' own strings. 12 of 12 placed; none omitted.

## Adaptations

1. **Console adapter.** `soft_workshop.gd` finds its partners through the Endless
   Museum's `_edit_records` ancestor and returns early without one. The adapter finds
   them among the same Void floor's mounts by their identity stamp, then runs the
   original desk code: chapter rows, controls, `_cloth_pins`, model calls. Inside the
   museum it calls the original `_bind`. The museum's hall fill lights, placed from
   `VESTIBULE_H` in museum coordinates, are not created.
2. **Floor-relative soft bodies.** `softbody3d.gd` moves a body below world y 1.0 to
   world y 2.0 at setup, and below world y -0.5 to world y 1.0 every frame. On Void
   floors at y -6 and -12 that sends the mill's pinned sphere and all four stop bodies
   onto the canopy. `void_soft_body.gd` applies the same two guards relative to the
   enclosing content floor. Everything else is the original.
3. **Tension bay relocated.** The Cloth map's reference bay (rows 47-67, behind a wall)
   would land at z -42. The membrane moves 32.5 m north to (1, -9.5), keeping its x and
   turned facing. Its own 14 x 12.5 m receiving plate fills the south half of floor 2.
4. **Radiolaria at 0.45 m.** Its forms are centred on the origin. At token scale 0.5
   the lowest point is about -0.42 m, so the museum's height 0 buried half of it.
5. **Fourteen provenance captions** (`route`), removable.

## Not transferred

- Deformation map: the interior walled room (rows 30-40, raised cells, no artifacts).
- Cloth map: the raised cells and the hole at rows 33-39, which `final.md` names as "the
  raised cells farther into the hall"; the bay wall at row 46.
- All perimeter walls, spawn and teleporter utilities, lighting, sky, `nature_layer`.

## Coupled instruments

- **Deformation console** binds `jelly_cube` (model) and `softmill` (other). STIFFNESS
  cycles 0.5/0.1/0.9, DAMPING 0.01/0.05/0.1, PRESSURE 1/0/2, RESET calls
  `_reset_physics`, MILL toggles processing on the mill's scripted parts (not the soft
  body), RULE shows the card. The readout shows all four.
- **Cloth console** binds `cloth_straps` (model) and `softstopscene` (other). PINS
  switches top row and top corners, using each strip's `lesson_rest` vertices. SUPPORT
  cycles gantry, none, hoop, mast and wall without touching pins. STIFFNESS cycles,
  RELEASE unpins, REBUILD rebuilds the strips with top-row pins, LANDING cycles
  floor/pan/rail/cone on the stop scene, which rebuilds and drops the four bodies again.
- Binding is by token per floor. A second copy of a partner token on the same floor
  would rebind to the last one, as in the museum.
- The console's `_process` hides CanvasLayers under its floor root every 0.5 s.
- `science_screen#mode:field` looks for a sibling with `noise_frequency` or
  `height_scale`. A Void mount has no such sibling, and neither did this hall, so the
  screen shows its fallback.
- Films (`concept_monitor`): PAUSE / REPLAY / STEP / ROUTE buttons, a private viewport,
  activated by gaze within 14 m. Their gaze raycast uses mask 1.
- Tension study: HOLD A PULL / RELEASE / LOAD / MORE-LESS GIVE, plus the pink bead.

## Bounds and risks for the native pass

| item | prediction | check |
|---|---|---|
| jelly cube | 0.6 m body 1 m up at (7, 4), about 0.78 m from shaft B's NW hole corner | the crown stem and label; visitor stands at +z |
| softmill | x -5.5..-2.6, z -1.1..2.2, 3.25 m tall, 2 m from the A hole | the arm's sweep at other angles |
| soft sphere | pinned point 1047 holds in world space at its rest pose | the inherited-scene script swap keeps every SoftBody3D property |
| stop bodies | x -5.5..-1.5, z -0.8..3.8; dropped from 3 m onto 0.55 m rails | rebuild on LANDING; timers 7.5/11/12/12 s start when the floor builds, so they may have stopped before arrival (as in the museum) |
| straps | x 6.6..9.5 at z 5, 3.8 m tall; 1.6 m north of shaft B | which side the wall support builds on |
| tension plate | x -6..8, z -15.75..-3.25; pierced by columns (±5, -14); 0.25 m south of B's hole at x 7.5..8 | membrane core x -2.1..4.1, z -10.8..-7.0 is clear |
| radiolaria | x -4.8..-1.2, z -11.6..-8.4, lowest point about +0.03 | particles inflate the measured AABB |
| science screen | 3.1 m face 1.5 m up; its stand floats, as in the museum | none |
| films | case 2.7 m wide on 0.55 m feet; floor-2 film 0.34 m from column (14, -14) | gaze activation through the console geometry |

Physics cost is unmeasured. The mill runs at precision 15. The four stop bodies have
about 2100 vertices each at precision 7. The floor also carries eight strap bodies and
six jelly bodies. Check whether floor residency sleep pauses SoftBody3D simulation.
`final.md` describes the base.tscn rig's TELEPORT collision hands. The Void rig's hand
contact with the jelly cube is untested.

Commands:

```bash
python tools/audit_void_transfer.py softbodies
```
```bash
python tools/export_void_trial.py softbodies
```

Editor: `http://localhost:3003/lab-editor?mode=void&trial=softbodies&floor=1`.


## Coordinator acceptance — 21 October 2026

Claude Opus completed and froze the package. Codex merged all proposed catalog
scene overrides, configured the stop scene before ready and exported 47 real
geometry models. Native desktop and synthetic XR tests pass 63/63; source
preservation passes 76/76; editor checks pass 15/15. The latter verifies every
placement can be copied, moved and rotated, then verifies native layout/Desktop
mirror save and reload, stale-save rejection and restoration of the test edits.

The first native run exposed Jolt placement transforms reaching soft bodies after
their floor had disabled physics. The loader now submits those transforms in a
live physics space before pausing preview content. Physical vertex positions,
not the SoftBody3D node transform, verify that pinned and falling bodies stay
inside the correct negative-height floor. The original sphere pin 1047 and
pressure/precision properties remain intact.

Verified operations include stiffness, damping, pressure, mill stop/resume,
reset, cloth pin patterns and supports, release/rebuild, landing changes, moved
and rotated console binding, film camera isolation, descent, sleep and retry.
This is not a physical-headset test or a test of every possible hand contact.
Exact soft-body vertex-state restoration and headset performance remain open,
as do the recorded tension-plate/column fit and source fallback/timer behaviours.
Two viewport texture cleanup diagnostics occurred only after successful export;
they are retained in the model manifest. Native interaction runs have no errors.

Chapter text, original museum sources and curated tower layouts were not edited
for this transfer. Curation follows the review; this package is not a finished map.
