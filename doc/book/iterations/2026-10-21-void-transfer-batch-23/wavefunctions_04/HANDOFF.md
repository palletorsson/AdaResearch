# wavefunctions_04: WaveFunctions_AirMusic (floor 1) and Wavefunctions_Sky_Stairs (floor 2)

Owner: Claude Opus, batch 23, 2026-10-21. Every result below comes from the final runs,
taken in the Godot slot one after another:

| Gate | Result |
|---|---|
| Source audit | **81 / 81** |
| Native (desktop + synthetic XR) | **141 / 141**, exit 0, no engine errors |
| GLB export | **49 models, no failures** |
| Editor | **17 / 17**; `rooms.json` hash `4d9c7da7…` identical before and after the editor's save/restore |

The tower is the standard one: 42 x 32 m, 6 m storeys, shafts at x ±10 (5 x 6 m), arrival
at (0, 12). Pillars and shafts are untouched. All 14 inventoried IDs appear exactly once,
each with:
- the original key and `#` config;
- facing = yaw + 180;
- the token's height and scale.

| Status | Count |
|---|---|
| Placed | 14 |
| Native verified | 14 |
| Editor verified | 14 |
| Curated | 0 |
| Headset | not tested (synthetic XR only) |

## Placement

Each hall is turned 180° rigidly so that its spawn `sp` lands on the arrival:
- AirMusic: `x = 9 - col`, `z = 14 - row`.
- Sky Stairs: `x = 12 - col`, `z = 14 - row`.

Twelve placements are rigid. Two moved off fixed tower parts.

| id | at | facing | h / scale | config |
|---|---|---|---|---|
| f1_resonating_metallophone_5_6 | 4, 8 | 0 | 0 / 1 | stand:table |
| f1_air_music_display_case_13_6 | -4, 8 | 0 | 1 / 1 | |
| f1_GlassRack_3_12 | 6, 2 | 180 | 0.7 / 1 | config:spiral_tube |
| f1_GlassRack_14_12 | -5, 2 | 90 | 0.7 / 1 | config:fractional_distillation |
| f1_lab_table_3_13 | 6, 1 | 180 | 0 / 1 | |
| f1_lab_table_14_13 | -5, 1 | 180 | 0 / 1 | |
| f1_RackAmbientDrone_14_15 | -5, -1 | 0 | 1 / 1 | |
| f1_SystemsMusicTest_5_16 | 4, -2 | 0 | 0.5 / 0.9 | |
| f1_dark_sphere_14_18 | -5, -4 | 180 | 0 / 1 | |
| f1_BigPipeSystem_3_19 | 6, -5 | 270 | 1 / 1 | path:straight,straight,up,straight,down,straight,straight |
| f2_cube_scene_5_6 | 7, 8 | 180 | 0.5 / 1 | |
| f2_sine_cylinder_staircase_7_16 | **1.5, -9.5** (rigid 5, -2) | 180 | 0 / 1 | |
| f2_math_objects_19_17 | **-5, -3** (rigid -7, -3) | 180 | 0 / 1 | |
| f2_dark_sphere_6_21 | 6, -7 | 180 | 0 / 1 | |

### Why the two moves

**Staircase.** Its tread band reaches r ≈ 4 m.
- At the rigid centre, the east water and electrical risers at (6.5 / 6.92, -4.2) lie
  inside the band, and the ring overlaps shaft B.
- At (1.5, -9.5) it clears shafts, risers, columns and the dark sphere.
- It also clears every floor-1 placement above it, which matters because its top passes
  through that slab (see Staircase).

**Math gallery.** It is 11 x 3 bodies, about 1.8 x 7.3 m as measured.
- At the rigid x = -7, one column of bodies sat on the west water riser (-6.5, -4.2), and
  objects overhung shaft A's landing pad.

Not transferred: walls, `sp`, `t`, `sub:map`, and the source `structure` plinths.

## Measured native bounds (metres above the floor)

| id | x | y | z |
|---|---|---|---|
| f1_resonating_metallophone_5_6 | 3.25..4.75 | 0.00..1.76 | 6.95..8.69 |
| f1_air_music_display_case_13_6 | -5.05..-2.95 | 0.60..1.26 | 6.95..9.05 |
| f1_GlassRack_3_12 (spiral_tube) | 5.99..6.17 | 0.69..0.98 | 1.91..2.09 |
| f1_GlassRack_14_12 (fractional_distillation) | -5.00..-4.02 | 0.59..1.19 | 1.83..2.18 |
| f1_lab_table_3_13 | 5.40..6.60 | 0.00..0.38 | 0.60..1.40 |
| f1_lab_table_14_13 | -5.60..-4.40 | 0.00..0.38 | 0.60..1.40 |
| f1_RackAmbientDrone_14_15 | -5.00..-4.04 | 1.00..1.63 | -1.01..-0.98 |
| f1_SystemsMusicTest_5_16 (5.4 m ring plane) | 1.30..6.70 | 0.05..0.95 | -4.70..0.70 |
| f1_dark_sphere_14_18 | -5.42..-4.58 | 0.01..0.96 | -4.42..-3.58 |
| f1_BigPipeSystem_3_19 | no runtime geometry | | |
| f2_cube_scene_5_6 | 6.50..7.50 | 0.00..1.00 | 7.50..8.50 |
| f2_sine_cylinder_staircase_7_16 | -2.16..5.19 | -0.22..**8.99** | -13.18..-5.82 |
| f2_math_objects_19_17 | -5.69..-3.88 | -0.11..0.26 | -6.53..0.72 |
| f2_dark_sphere_6_21 | 5.56..6.44 | 0.01..0.96 | -7.45..-6.55 |

The native fit check passes on both floors in both modes. No placement geometry enters:
- either **whole** shaft opening (5 x 6 m, the full storey height);
- the 2 x 2 m arrival;
- the default floor sign (3.5, -7.8, 3.7 x 1.65 m).

On floor 2 the sign stands under the stair ring. The lowest treads above it clear its
top, so I did not move it.

## Staircase: exact numbers

| measure | value |
|---|---|
| Treads | **80**, each rising **0.11 m** (scene `STEP_RISE`), 0.22 m thick |
| Tread tops | 0 → **8.69 m** above floor 2 |
| Overall geometry | -0.22 → **8.99 m**: tread undersides, plus membrane bridge colliders 0.3 m above the treads |
| Clear storey height | 5.64 m (upper slab underside at -6.36) |
| Treads ending above the slab underside | **28** |
| Headroom for a 1.7 m body | lost from tread **36** (top 3.96 m) |
| Standing on tread 10 (1.1 m), placed | holds: desktop +0.06 m, XR +0.08 m |
| Walking climb, desktop | **2.13 m**: 7 treads walked, 2 jumped, then stalled 3 treads running |
| Walking climb, synthetic XR | **1.00 m**: 1 walked, 1 jumped, then stalled |
| Seen from floor 1 | 21 treads stand above floor 1: not visible, not processing, no collision (floor residency) |

Climbing stalls well below the headroom limit. I did not diagnose why (the step edges, or
the floating membrane risers). Physical-headset comfort is untested.

The stair was **not** cut or scaled. A real two-storey stair would need a slab opening,
which is an architecture change and is not requested now (REQUESTS.md R3).

## Interactions: what each work does, and the evidence

| id | action / animation | evidence (native, both modes unless stated) | fit / dependency | remaining |
|---|---|---|---|---|
| metallophone | 8 tuned bars; striker strikes; sum readout; striker returns to its cradle | **real grab** of the original striker (mouse / grip). **Held-tip** strike rings bar 0, then bar 3 overlaps it. Readout sums ≥ 2 windows of 512 samples. Dropped striker returns. | `metallophone_local.gd` freezes the bars (Jolt rejects six axis locks); StrikeZones intact | listening quality untested |
| display case | scaled Systems Music loop; VOLUME slider | the case's own loop runs (scale 0.35, period 90 s). **Real pointer drag** of VOLUME: −12 → −40 dB on every voice. The drag went to the slider's minimum. | `air_music_case_local.gd` fixes the slider's call arity | |
| GlassRack x 2 | static apparatus | token config builds: spiral_tube 2 meshes, fractional_distillation 40, no coffee-rack frame | R1 adapter; racks float 0.7 m beside their tables, as in the source | |
| lab_table x 2 | static | geometry and config meta | top at 0.38 m | |
| RackAmbientDrone | PLAY / STOP; 3 sliders | **real pointer** PLAY starts and STOP silences the voice. FREQ is a **slider-API** check (515 Hz). | creates its own audio bus (source behaviour) | AMP / DUR not exercised |
| SystemsMusicTest | 7 timed phasing loops | loops started and the synth is bound. No Area3D, so no visitor-position trigger exists, whatever the catalog text says. | non-positional synth on a runtime bus | |
| dark_sphere x 2 | pulse | geometry | source 1 m plinths absent | |
| BigPipeSystem | none | `auto_build` off, `_curves` empty, inert path token; editor marker exported | source is empty | marker only, not a pipe |
| cube_scene | static reference | its own collision under a ray | source 1 m plinth absent | |
| staircase | walk / climb | see Staircase | slab conflict | curation |
| math_objects | 33 pickable bodies | all 33 on grab layers. **Real grab** of the aimed Trefoil (source layer 1) and of a wrapped surface. Bodies stay on floor 2. | `math_gallery_local.gd`; at floor level, not on the source 1 m platform. The XR collision hand displaced the target 0.52 m before the grab. | reach comfort |

Shared chain, both modes: safe arrival, open shafts, visitor camera, shaft-pad descent to
floor 2, sleeping floor 1, return, retry.

## Screenshots (`evidence/`, desktop, native Mobile renderer)

| # | file | view |
|---|---|---|
| 01 | `01-airmusic-arrival-eye.png` | arrival, eye height, avatar hidden |
| 02 | `02-metallophone-eye.png` | metallophone at eye height |
| 03 | `03-racks-drone-case.png` | racks, drone, case |
| 04 | `04-systems-music-pipe.png` | Systems Music and the pipe position |
| 05 | `05-floor1-stair-crowns.png` | floor 1 over the stair ring: empty, as residency predicts |
| 06 | `06-skystairs-arrival-eye.png` | Sky Stairs arrival |
| 07 | `07-staircase-into-slab.png` | the helix rising to the slab |
| 08 | `08-math-objects-eye.png` | gallery at floor level beside the shaft A pad |
| 09–10 | `09-editor.png`, `10-editor-sky-stairs.png` | editor |

## Commands

Run serially, with `GODOT_EXE=…/Godot_v4.6-stable_win64.exe`:

```
python tools/audit_void_transfer.py wavefunctions_04
python tools/test_transfer_native.py wavefunctions_04
python tools/export_void_trial.py wavefunctions_04
node tools/test_void_transfer_editor.cjs wavefunctions_04
```

## Errors and limitations (honest record)

Native ran nine times; each run's logs were inspected before the next.

| Runs | What happened |
|---|---|
| 1 | **My probe error.** A static `is XRToolsPickable` compiled `player_body.gd` before its autoload existed. The broken XR Tools chain invalidated all of XR. Now duck-typed. |
| 2 | 6 failures. Desktop tip steering diverged (2.57 m). The gallery aim went to the wrapper origin. |
| 3–4 | A damped aim loop still missed by 0.66–0.78 m. Replaced in run 5 by a geometric solve of DesktopHand's camera-fixed grip pose (lateral offset 0.46 m, stand 1.9 m back); tip error is now ≤ 1.3 mm. |
| 5–6 | The gallery miss was measured: 12 source bodies sit on physics layer 1, outside both grab masks. Codex added `math_gallery_local.gd`. |
| 7–8 | The XR hand nudged the aimed wrapped body. The hand now lifts, crosses over the lattice and descends. |
| 9 | Clean. |

- **Repo-root walk.** Early on, one read-only grep walked from the repo root and may have
  entered the `ada_run` junctions. I stopped it after about two minutes; nothing was
  written or deleted.
- **Untested.** Physical headset, listening quality, the drone's AMP and DUR sliders, and
  a full climb.

## Exact files

**Changed by me:**
- `commons/void/trials/wavefunctions_04/rooms.json` (floors 1–2 only)
- `commons/void/trials/wavefunctions_04/probe.gd` (new)
- `commons/void/trials/wavefunctions_04/REQUESTS.md`
- `commons/void/trials/wavefunctions_04/STATUS.json`
- `commons/void/trials/wavefunctions_04/HANDOFF.md`
- `commons/void/trials/wavefunctions_04/transfer-status.json`
- `doc/void-transfer/2026-10-21-batch-23/GPU_SLOT.json` (released to Codex)

**Generated by the runners:**
- `commons/void/trials/wavefunctions_04/evidence/*`
- `../ada_encyclopedia/public/void-trials/wavefunctions_04/*` (manifest and 49 GLBs)
- `commons/void/line_parts.json`, rewritten at 18:39 during my final export (the task
  permits this)
- the Desktop mirror, written and restored by the editor test

**Not touched by me:** shared runtime (Codex installed the adapters), source artifacts,
maps, chapter texts, catalog, `playable.json`, `layout.json`.
