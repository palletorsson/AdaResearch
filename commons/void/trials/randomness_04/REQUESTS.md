# randomness_04: shared-code requests (Claude worker A, batch 25)

All requests are trial-scoped (`trial_id == "randomness_04"`). No source scene, script,
map or text is touched. "Static" means read from the source before any native run;
each request names the native check that will measure it. The checks that depend on a
request carry "(needs Rn)" in their names, so a native run before installation fails
exactly those checks and nothing else.

Order of value: **R1, R2, R4** are needed for acceptance as written; **R5** is
recommended; **R3** is conditional.

## R1. Install the museum exhibit stage, as for randomness_02 (static)

**Placements and the keys only the stage reads** (no artifact script reads them):

| id | keys |
|---|---|
| f3_random_walk_128_9_17 | glass_width 12, glass_depth 12, glass_height 5, glass_title WALK / RETAIN, glass_moat true |
| f5_mushrooms_8_11 | glass_width 8, glass_depth 8, glass_height 4.5, glass_title POPULATION / DIFFERENCE, glass_entry 4, controls compact, control_front 5.1 |
| f3_random_walk_terrarium_9_5 | controls compact, control_front 1.25 |
| f4_distribution_sampler_5_6 | controls compact, control_front 1.05 |
| f5_silhouette_arrivals_13_17 | controls compact, control_front -1.65, control_facing -z |
| f5_couture_comparison_8_20 | controls compact, control_front -1.7, control_facing -z |

**Evidence (static).** `endless_museum.gd:13363` installs
`museum_exhibit_stage.gd` on every placed node after `add_child`. In the Void,
`floor_content.gd:444` does so only for `randomness_02`, so these keys reach the node as
`config_*` metadata and build nothing: no glass, no moat rails, no reach consoles.

**Exact hook** (`floor_content.gd`, the existing line 444 branch):

```gdscript
if trial_id in ["randomness_02", "randomness_04"]:
	# These source tokens include their museum glass enclosure/compact
	# console. Reuse the original furnishing adapter, not just its metadata.
	preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd").install(artifact, source_config)
```

`install()` returns at once for the 69 placements without `glass_width` or
`controls:compact`. Measured by: `terrarium keypad sits on the compact console`,
`128 walk stands in its WALK / RETAIN glass`, `sampler keypads ...`, `mushrooms stand
in the ... glass`, and the moat-rail fit check below.

**Fit consequence, already handled in the probe.** The moat ring is 12 m + 3 m = 15 m
across; the gap between the shafts is exactly 15.0 m. The two 5 cm side rails stand on
the shaft edges, so they overhang each shaft opening by about 0.025 m. The probe
measures that on its own (`moat rails overhang each shaft opening by at most 0.03 m`),
as randomness_03 did for its 15.1 m canopy. Nothing is shrunk.

## R2. Keep source keyboard fallbacks off the Void's keys (static)

Five sources read keys in `_input()` that the Void desktop visitor uses for itself:

| artifact | keys read | effect in the Void | same action on its panel |
|---|---|---|---|
| hardware_entropy_decay | ui_accept (Space, Enter), ui_home | every jump pauses / unpauses the rig | PAUSE, RESET |
| random_decay_multimesh | ui_accept, ui_home | every jump stops / starts the decay | TOGGLE, RESET |
| distribution_sampler | Space, C, S, 1-4 | jump toggles auto-sampling; walking back (S) adds samples; C clears | cabinet PAUSE / BATCH, CLEAR, law buttons |
| galton_board | Space, R, D | jump toggles AUTO; strafing right (D) drops balls | DROP, AUTO, RESET |
| pixel_cloud | ui_accept | every jump rebuilds the (seeded, identical) cloud | none needed |

Not included: random_walk_terrarium (R is the Void's retry, which reloads the floor
anyway; 1/2/3 are not Void keys).

**Exact hook** (`floor_content.gd`, after `mount.add_child(artifact)`, i.e. after `_ready`
has enabled input processing for the overridden `_input`):

```gdscript
if trial_id == "randomness_04" and item.artifact in ["hardware_entropy_decay", "random_decay_multimesh", "distribution_sampler", "galton_board", "pixel_cloud"]:
	# Source keyboard fallbacks read Space/Enter (Void jump), R (retry), C, S, D (walk).
	# Every action stays on the artifact's own pointer panel.
	artifact.set_process_input(false)
```

Measured by (desktop, real key event): `<id> ignores the Void's Space key` on floors 2
and 4 and `pixel cloud is not rebuilt by the Void's Space key` on floor 3.

## R3. Conditional: retire random_decay_multimesh's current camera before tree entry (static)

`random_decay_multimesh.tscn` has a `Camera3D` with `current = true`, the only such
camera in this trial. On tree entry it takes the viewport; the museum-import clean-up
then sets `current = false`, and Godot hands the view to the next registered camera,
which need not be the visitor's. Install **only if** `visitor camera remains active`
fails on floor 2:

```gdscript
if trial_id == "randomness_04" and item.artifact == "random_decay_multimesh":
	var view := artifact.get_node_or_null("Camera3D")
	if view != null:
		artifact.remove_child(view); view.free()
```

(before `mount.add_child(artifact)`, like the shelf branch).

## R4. Two trial adapters with editor markers (scripts written; need wiring)

**a. `random_object_spawner_local.gd`** (both spawners). Static reading:
`spawn_cube()` passes `new_cube.position` (local) to `play_wood_sound()`, which assigns
it to `wood_sound.global_position`, so every knock sounded near world (0, 1, 0), above
the roof. The adapter maps it through the placement's own transform. Its
`prepare_editor_preview()` shows the hidden template at the spawn point with a label
when the export snapshot comes before the first arrival (first cube after about 1 s;
the exporter waits 30 physics frames). Measured by: `wood knock sounds at its own
spigot (needs R4)`.

**b. `rotate_no_grid_preview.gd`** (f2_Random_Rotate_Random_XYZ_3_10). The source owns
no geometry and finds no `GridMultiMesh` under a Void mount (nor in the museum: its own
note). It exports no GLB, which breaks the editor test. The adapter adds a labelled
`DEPENDENCY MISSING / NO GRID FLOOR` marker in `prepare_editor_preview()` only. The scene
overrides `selection_mode = 1`, `bell_center = (4, 1, 4)`, `bell_radius = 3.0` and
`noise_source`; keep them across the swap.

**Exact hooks** (`floor_content.gd`, before `add_child`, with the other trial swaps):

```gdscript
if trial_id == "randomness_04" and item.artifact in ["random_object_spawner", "Random_Rotate_Random_XYZ", "galton_board"]:
	var keep: Dictionary = {}
	for property in artifact.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
			keep[property.name] = artifact.get(property.name)
	match str(item.artifact):
		"random_object_spawner": artifact.set_script(preload("res://commons/void/trials/randomness_04/random_object_spawner_local.gd"))
		"Random_Rotate_Random_XYZ": artifact.set_script(preload("res://commons/void/trials/randomness_04/rotate_no_grid_preview.gd"))
		"galton_board": artifact.set_script(preload("res://commons/void/trials/randomness_04/galton_board_local.gd"))
	for key in keep: artifact.set(key, keep[key])
```

(Drop the `galton_board` entry if R5 is declined.)

`tools/test_void_transfer_editor.cjs:27`, label only:

```js
const dependencyMarker=(trial==='randomness_03'&&['f2_remove_random_1_2','f2_pickup_cube_placer_1_3'].includes(entry.id))||(trial==='randomness_04'&&entry.id==='f2_Random_Rotate_Random_XYZ_3_10');
```

## R5. Recommended: galton ball spawn on a scaled board (adapter written)

**Static reading.** `galton_board.gd:695` spawns each ball at
`global_position + Vector3(jitter, _funnel_top_y + 0.02, z_jitter)`: a board-local
offset added in world units. The token scales the board 1.5x
(`galton_board:180:0.9:1.5`), so the funnel's intended entry (0.57 board units) stands
0.86 m above the origin, but the ball appears 0.57 m above it: 0.38 board units, below
the first three of eight peg rows. The museum plan applies the same scale, so this is a
source seam, not a Void one. `galton_board_local.gd` reads the same offset as
board-local (`to_global`), which stays right under any move, turn or rescale. The scene
has no exported overrides. Measured by `galton ball enters at the funnel of the 1.5x
board (API spawn; needs R5)` and the printed `GALTON spawn local y`.

If Palle prefers the museum's behaviour, decline R5; the check then documents the seam.

## State after integration (coordinator, 20:38)

Codex wired R1, R2, R4 and R5 (`floor_content.gd` lines 263-274, 447-450, 484-487;
editor label line 27); R3 deferred. bounds-2 desktop already passed `visitor camera
remains active` with the hooks live, so R3 stays unneeded unless XR shows otherwise.

## R7. Dice RESET under Jolt: freeze statically for the teleport (adapter written; needs wiring)

**Measured** (debug `dice`, desktop): after a throw the die settled on the floor at
(-3.13, -5.96, 10.63). A real pointer RESET reached `Btn_0` (PRESS_TRACE) and
`_reset_dice()` ran (result blanked to "?", rain cleared), but the die stayed there,
1.10 m from its spawn, unfrozen.

**Source** (`dice_throw.gd:978`): `freeze = true`, write `global_position`, then
`set_deferred("freeze", false)`. The die is an XR Tools pickable, and `pickable.tscn`
sets `freeze_mode = 1` (KINEMATIC). Static reading of the mechanism: a frozen kinematic
body takes the written transform as its target for the next physics step, and the
deferred unfreeze lands first, so the move is dropped. A STATIC-frozen body moves at
once: the galton pool balls (plain `RigidBody3D`, static freeze) are respawned with the
same pattern and were measured at their new position before falling. The museum runs the
same engine, so it very likely shares this; it shows only when the die has left its spawn.

**Adapter:** `dice_throw_local.gd` overrides `_reset_dice()` to freeze in static mode for
the teleport and restore the pickable's mode after the deferred unfreeze. Nothing else
changes; pickup still freezes kinematically. The scene has no exported root overrides.

**Exact hook:** add `dice_throw` to the existing randomness_04 swap block
(`floor_content.gd:263-274`):

```gdscript
if trial_id == "randomness_04" and item.artifact in ["random_object_spawner", "Random_Rotate_Random_XYZ", "galton_board", "dice_throw"]:
	...
	var random_adapters: Dictionary = {
		"random_object_spawner": "random_object_spawner_local",
		"Random_Rotate_Random_XYZ": "rotate_no_grid_preview",
		"galton_board": "galton_board_local",
		"dice_throw": "dice_throw_local",
	}
```

Measured by `dice RESET returns the die to its spawn on the felt from wherever it settled
(needs R7)` and the `BODY_SAMPLE die after RESET` trace (positions for 12 frames after the
press).

**Same pattern, not adapted (static):** `paired_die.gd:return_to_tray()` (paired column
and continuing die; also their automatic return after 0.7 s off the tray) and
`random_walk_leash.gd:_reset()` (the orb pickable) write a kinematic-frozen pickable's
transform and unfreeze deferred. The trays are built in code from a preloaded script, so a
floor_content swap cannot reach them without adapters for both hosts. Recorded; a die that
leaves its tray probably stays off it until picked up.

## Galton: two source defects measured, recorded (no request)

Measured on debug `galton` (desktop):
- **Pool counted at build.** `_init_ball_pool()` adds the 50 hidden, frozen pool balls at
  the board origin, the centre bin's floor, inside bin 4's sensor. Each is counted once at
  build: `dropped=50 bins=[0,0,0,0,50,0,0,0,0]` with no ball dropped. The histogram and
  bell readout start from that 50-count spike. Each phantom count also schedules a recycle
  1.5 s later, which hides any ball spawned from the pool in that window (mid-air).
- **Uncounted side gaps.** The nine bins span x ±0.216 board units; the board is 0.5 wide
  (walls at ±0.253). A ball that leaves the peg triangle comes to rest in a side gap with
  no sensor: the traced ball rested at local x 0.238, y 0.009 and was never counted.
- **The board scatters to its edges.** Trace (desktop): the ball strikes peg 0 almost
  dead centre (x 0.0024) at frame 10 and leaves with 0.22 m/s sideways, then 0.32 m/s at
  frame 20 and 0.78 m/s at frame 40 (x 0.157, outside the triangle by row 4-5), and
  drops beside the wall. Two five-ball runs on the source's funnel path: desktop 0/5 in
  a bin (x 0.241, 0.241, -0.226, -0.241, -0.241), XR 2/5, both in bin 8, the outermost
  (0.179, 0.192; three at ±0.241). The source's own parameters do this: restitution 0.3,
  friction 0.15, an 18 mm ball (scaled) passing between 14 mm pegs on a 48 mm pitch, and
  bins only as wide as the triangle's base. A uniform 1.5x scale keeps the geometry
  similar (only damping and gravity in board units differ), so the scale is not the
  driver. R5 is relevant: it restores the source's intended funnel entry, so balls hit
  peg 0 and cross all eight rows. Without R5 (the museum, where the 1.5x scale drops them
  at board-local 0.38) they start below row 2 and cross about five. Diagnostic
  `galton-spread` measures both paths, ten balls each, for that decision; it is not part
  of acceptance.

All of these are the source's, in the museum as here (the edge scattering's degree
there is unmeasured). If wanted, the existing `galton_board_local.gd` can park the pool
clear of the sensors (no other change):

```gdscript
func _init_ball_pool() -> void:
	super._init_ball_pool()
	for rb in _ball_pool: rb.position = Vector3(0, _funnel_top_y + 0.1, 0)
```

Probe (robust to the scatter): five funnel balls must all reach the bin row (physics
outcome); where they rest, and how many fall inside the bins, is printed and kept as a fit
note, not asserted. Counting is tested deterministically: one ball released inside the
centre bin, below the last peg row and between its dividers, must be counted in bin 4.

## R6. Optional, shared probe/exporter: an empty mesh is not geometry (measured)

bounds-3 measured `f3_random_draw_dot_6_8` at x 0.00..3.25, y 0.00..18.00 above floor,
z 0.00..4.58. Cause (source read, `commons/primitives/point/draw_dot.gd`): `_setup_trail()`
makes `DrawTrail`, a top-level `MeshInstance3D` (line 135) at identity, i.e. at the world
origin, whose `ImmediateMesh` has no surface until the dot is held and moved; trail
points are appended in world coordinates by design (line 499), so a drawn line lands
where the dot went on any floor, moved or turned. Not a seam in the artifact. The
shared `geometry()` walker appends `global_transform * mesh.get_aabb()` for that empty
mesh: a zero-size box at world (0, 0, 0), merged into the dot's bounds. The fit check
passed only because a zero-size point at world zero misses every keep-out box, and
`inspect_floor` will log a false "geometry_top above ceiling" fit note for it.

My probe overrides `geometry()` to skip meshes with `get_surface_count() == 0` (they
render nothing). The same one-line guard would help the shared walker in
`tools/probes/void_transfer_probe.gd:133` and, if the exporter's `collect()` copies
empty meshes, `tools/probes/export_void_editor.gd:248`:

```gdscript
elif node is MeshInstance3D and node.mesh!=null and node.mesh.get_surface_count()>0 and node.is_visible_in_tree() and node.layers!=0:
```

## Recorded, not requested

- **random_walk_collection `bench_bare_rack:1`** is read only in `_ready`; the Void's
  config arrives after. Its effect is to free two meshes that never render (one has no
  mesh; one sits under a hidden Sprite3D), so nothing visible differs and neither the
  probe nor the exporter counts them. `configure_before_ready` would apply it if wanted.
- **distribution_comparator SAMPLES slider** looks for `DISTRIBUTIONS/Param_0`, but its
  panel is named `RackPanel` (RackTemplates names a title-less panel so), so the slider
  never changes `_sample_count`. Source defect, reported by the diagnostic
  `comparator`; RESAMPLE works.
- **random_walk_leash** draws its leash line and trail from
  `_orb_body.global_position - global_position` as if local: right at facing 0 (this
  placement), mirrored if an editor turns it. Source, recorded.
- **Edible mushrooms** heal through `/root/GameManager` (the museum's), not the Void's
  health, and add their perception overlay to the current scene. Eating is not run.
