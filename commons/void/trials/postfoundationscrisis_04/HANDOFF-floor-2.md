# PostCrisis_Synthesis (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**
Static checks: `floor-2.json` substituted into this trial's `rooms.json` in memory
validates against `rooms.schema.json`. All seven IDs appear once with their `#` configs.
**No new adapter is required.** `florensky_sphere` already resolves through the catalog
to Codex's `postfoundationscrisis_02/florensky_void.tscn`.

## Placement

The source hall (16 x 16) is turned 180°: `x = 7 - cell_x`, `z = 12 - cell_z`,
`facing = source rotation + 180`. The entrance (7,1) lands at the arrival (0, 12).
Everything stands between x -5 and 6, at least 3.5 m from both shaft holes.

| id | at | facing | height | scale | config | height reason |
|---|---|---|---|---|---|---|
| `f2_tt_2_1` | 5, 11 | 270 | **1.4** | 1 | none | batch-07/08 `tt` precedent |
| `f2_edge_ground_synthesis_5_2` | 2, 10 | 270 | 0 | 1 | none | token (rotation 90 only) |
| `f2_bias_from_inside_8_2` | -1, 10 | 180 | **1.085** | 1 | none | token 0.3 buries its 1.085 m stand (`_create_stand`); accepted batch-07 precedent |
| `f2_qfep_formula_3d_11_2` | -4, 10 | 180 | 2 | 1 | none | token `:0:2` |
| `f2_florensky_sphere_2_5` | 5, 7 | 180 | **1.1** | 1 | none | token 0.4 puts the adapter's OBSERVE/CYCLE panel (local y -0.15) at 0.25 m; batch-08 floor 1 uses 1.1 |
| `f2_accountability_ledger_11_10` | -4, 2 | 0 | 0.65 | **1.8** | log_interval 6, visitor_record true | token `:180:0.65:1.8` |
| `f2_assembly_return_7_12` | 0, 0 | 0 | 0 | 1 | none | token |

**Not transferred:** the central raised block (structure 2/3 at rows 6-9, cols 6-9, with
no artifacts), the `el:3:1`, `3t:` and `sub:map` utilities, the teleporter `t:lab`, and
walls.

## The `tt:90:qfep_synthesis:180:0.5` token: what actually runs

- **Grid lane.** The interactables layer has no `tt:` branch; `GridInteractablesComponent`
  dispatches only `mc:`, `gridagent:`, `criticalinfo:` and `cluster:`.
  `_parse_token_params()` has no five-field branch. The result is lookup `tt` with **no
  overrides and no config**. `codeDisplay.gd` `apply_grid_config()` never receives
  `tutorial`. Your batch-07 native check showed this displays the bundled generic
  `TextUIControl` content.
- **Museum plan** (`em_plan.json`): rotation 90, **scale 180.0**, no config. The 180 is a
  mis-parse, not a scale to keep.
- **Authored intent.** The tail matches the utility format
  `tt:<name>:<rotation>:<up>:<scale>` (`GridUtilitiesComponent._parse_tutorial_display_utility`):
  name `qfep_synthesis`, rotation 180, up 0.5. That content exists at
  `commons/context/clipboard/tutorial_text/qfep_synthesis.md`. This is **not** a height
  of "qfep_synthesis".
- **Transfer.** Executed behaviour is kept, matching the accepted batch-07/08 `tt`
  entries: `config {}`, scale 1, facing 270 (the museum's 90 + 180), and height 1.4
  because the 1 x 1.2 m panel is centred on its origin. Showing the intended text would
  need `config {"tutorial": "qfep_synthesis"}`, which is a content decision for curation.

## Interactions (handler bodies read)

- **`bias_from_inside`, working.** The COMPRESSION slider calls
  `_on_perspective_changed()` → `_apply_perspective()`. READ / CLOSE toggles `_reading`.
- **`florensky_sphere` via `florensky_void.gd`, working.** OBSERVE calls `observe()` and
  CYCLE calls `cycle_state()` in `florensky_sphere.gd`. The defaults are
  `allow_observation` true and `hold_both` false, so neither returns early.
- **`accountability_ledger`, no controls.** With `visitor_record` true, `_process()`
  calls `_refresh_record()` every 1 s from `AssemblyPoseRecord.read()`. `log_interval: 6`
  is retained but drives only the non-visitor `_push_entry()` path, so it is inert here,
  as in the source. Config is read only in `apply_grid_config()`: the first `_ready()`
  build is the illustrative ledger, and the config call rebuilds it.
- **`assembly_return`, no controls.** `refresh()` runs every 1 s from the same record.
  It draws the blue starting pose from `assemblies.json` (VRBody) and, when a record
  exists, the amber kept pose.
- **Observation only:** `edge_ground_synthesis` (`_process` readout and packets) and
  `qfep_formula_3d` (pulse; `reading_study` off, so no term buttons).

## World dependency (not an adapter)

`AssemblyPoseRecord.read()` takes SceneTree meta `ada_assembly_pose_record`, otherwise
`user://ada_research/assembly_pose.json`. This trial contains no Assembly Laboratory, so
nothing in it writes a pose. On a fresh or isolated profile both artifacts show their
designed empty state: "NO POSE KEPT YET" and "No pose kept yet.". With a pose kept
earlier in the museum, they show it ("saved locally"). Probes using isolated `user://`
see the empty state unless they set the meta or the path key `ada_assembly_pose_path`.

## Focused checks (shared probe helpers)

```gdscript
if level == 2:
	var tt: Node3D = station("f2_tt_2_1")
	check(tag+"tt keeps executed config (no tutorial key)", not tt.has_meta("config_tutorial"))
	var f: Node3D = station("f2_florensky_sphere_2_5")
	await approach(f, 1.6)
	var before = f.current_state
	await press(f.controls.find_child("Btn_1",true,false))   # CYCLE
	check(tag+"CYCLE changes the antinomy state", f.current_state != before)
	var ledger: Node3D = station("f2_accountability_ledger_11_10")
	var ret: Node3D = station("f2_assembly_return_7_12")
	check(tag+"ledger in visitor-record mode, return draws the starting body", ledger.visitor_record and ret.bodies.get_child_count() >= 1)
	# optional: set get_tree() meta "ada_assembly_pose_record" to a valid record and expect a KeptPose within ~1.2 s
```

## Fit notes

- The arrival row is crowded, as in the source. The word-positions controls at
  (-1, 9.0) are 1.3 m from the arrival, and the formula floats at 2 m beside them.
- The ledger at scale 1.8 is about 1.75 x 1.13 x 0.67 m (registry AABB scaled),
  0.65 m off the floor.
- The return bodies' labels sit at local y 2.65 and their figures at x ±2.35. The
  footprint is about 6 m wide at the floor centre, clear of the shafts.
