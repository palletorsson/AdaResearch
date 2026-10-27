# noise_02: shared-code requests (Claude worker C, batch 25)

All requests are trial-scoped. No source, shared runtime or tool file is touched by this
worker. "Static" means read from source before any native run; the probe cases named
under each request measure it.

**State (2026-10-21, after native, export and editor runs):**

| Request | State |
|---|---|
| R1 | wired by Codex; verified natively (`lattice` 10/10, `panel` 8/8, full acceptance) |
| R2 | wired by Codex; one mesh per room (`rooms`: womb 768-1011 ms, atrium 1779-2025 ms) |
| R3 | wired by Codex; export of 55 models, no failures, strands meshed |
| R4 | **measured**, see below. Still open for Codex |

## R1. Configure two stand tokens before `_ready` (static; blocking for floors 2 and 3)

**Placements:**
- `f2_perlin_terrain_sculptor_13_7`: `stand:lattice seed:31415 keyboard:off`;
- `f3_shader_noise_space_6_4`: `stand:panel`;
- `f3_shader_noise_space_6_6`: `stand:room`.

**Problem.**
- `perlin_terrain_sculptor.gd` reads `stand` and `seed` only from `_grid_config`, inside
  `_ready()` (lines 154-171). `_grid_config` is written by `apply_grid_config()`, which
  `floor_content.gd` calls after `add_child` (no `configure_before_ready` in the catalog).
  In the Void the bench therefore builds the legacy sculptor: random seed, its own
  sliders and info label, keyboard shortcuts live for that frame (Up/Down/Left/Right, R,
  N). The later `apply_grid_config` sets `stand = "lattice"` without rebuilding. The
  consequences reach two other works: the voxel volume gets `contract: false` and keeps
  its own simplex field, and the science screen's `voxel_slice_data()` finds no lattice
  ("Waiting for this hall's lattice. No substitute field.").
- `noiseroom.gd` (`shader_noise_space`) decides `stand` in `_ready()` (lines 102-118);
  its `apply_grid_config()` only sets the variable. In the Void both placements build the
  legacy 18 x 13.6 x 27 m enclosure (16 x 12 m CSG walls, ceiling and floor at +/-6.75 m,
  four omni lights, a Camera3D with its own Environment), and `_input` stays live for
  Space (`ui_accept`, the Void's jump) and Esc. The board, the five-metre room and the
  in-hall broadcast never exist.

**Safe before `_ready`.** Both `apply_grid_config` bodies only assign variables (the
bench's `set("stand", ...)`; the room's `stand`, `set_layers` only with a `layers` key,
which is absent). Neither touches the tree.

**Exact hook** (`floor_content.gd`, beside the randomness_03 line after
`var before_ready := ...`):

```gdscript
if trial_id == "noise_02" and item.artifact in ["perlin_terrain_sculptor", "shader_noise_space"]:
	# Their stand tokens are read in _ready: bench lattice, panel board, museum room.
	before_ready = true
```

**Measured by:** `--focus lattice` (floor 2), `--focus panel` (floor 3), and readiness
checks "floor 2/3 construction complete".

## R2. Configure the two cellular rooms before `_ready` (static; efficiency only)

**Placements:** `f5_cellular_womb_space_17_19`, `f5_cellular_atrium_space_51_19`, each
`floor:false plinth:0 pin:true`.

**Problem.** `cellular_volume.gd` meshes the whole membrane in `_ready()` with the
default `create_floor = true`. `apply_grid_config` then sets `create_floor = false` and,
because the node is ready, calls `regenerate()` again. The result is correct (no floor),
but each room is meshed twice, on the floor's build frame and in the exporter. The
signed-field mesher samples about 27 x 11 x 29 m at 0.42 m: tens of thousands of
samples; the atrium's CELLS layout tests 20 sites per sample. `build_msec` is printed by
`--focus rooms` (it reports the second build only).

**Hook**, same place, if Codex wants it:

```gdscript
if trial_id == "noise_02" and item.artifact in ["cellular_womb_space", "cellular_atrium_space"]:
	before_ready = true # apply_grid_config only sets fields while not ready: one mesh, not two
```

## R3. Exporter: finish the voronoi weave before the snapshot (static)

**Placement:** `f5_voronoi_strands_34_40`.

**Problem.** The strands build their network two physics frames after `_ready`, then a
spider lays it at 2 m/s (`voronoi_weaver.gd`). `_commit` raises each MultiMesh's
`visible_instance_count` one segment at a time. `export_void_editor.gd` waits 30 physics
frames and then exports `visible_instance_count` instances (line 237). The GLB would
therefore hold the spider and about a metre of cord, not the net. The editor would place
a near-empty box.

**Hook** in `tools/probes/export_void_editor.gd`, after the 30-frame wait, beside the
colour-ball and Cage readiness loops:

```gdscript
for exhibit in building.content.exhibits.values():
	var web: Node3D = exhibit.get_node("Artifact")
	if str(web.get_meta("artifact_lookup_name", "")) != "voronoi_strands": continue
	for attempt in range(120):
		if int(web.generation_count) > 0: break
		await physics_frame
	if int(web.generation_count) == 0:
		failures.append("%s: voronoi network was not built" % exhibit.name)
	elif is_instance_valid(web.weaver) and not web.weaver.finished:
		web.weaver.finish() # the weaver's own "show the full structure" method
```

In the native game the weave runs as authored. `--focus strands` calls `finish()` by API
only to measure the released tension net, and says so.

## R4. Flight zone ignores residency (measured; open)

**Measured** with `--focus flightseam --mode desktop` (5/5 checks,
`evidence/debug/flightseam-desktop/checks.json`). On floor 1, at (-6, -17), 1 m above
floor 1 and just beyond its open north edge, the floor-2 flight zone answers:
- `flight_zone_active: true`, `glass_wall_collision: none`, `zone_visible: false`,
  `zone_processing: false`;
- the same both as first loaded from floor 1 and after visiting floor 2 and returning;
- checkpoint 1 in both.

So a floor-1 visitor who steps off the north edge between x -20 and 8 meets no glass wall.
They enter flight in a box they cannot see, instead of falling. The walk itself was not
run. The fix stays Codex's call; the hook below is unchanged.

Original request text:

**Placement:** `f2_voxelnoise_16_24` (`flight_box:true`), which stands beyond the north
edge (see HANDOFF).

**Problem.** `museum_flight_box.at_point()` returns any zone in group
`ada_museum_flight` whose box contains the point. It does not check visibility or
processing. The zone's box is 28 m tall, from floor 2 up to 16 m above the roof, at x
-20..8, z -44.1..-16.1. When the visitor is on floor 1, floor 2 is paused or hidden by
`floor_residency.gd`, which also removes the glass walls' collision
(`DISABLE_MODE_REMOVE`) for units not near a shaft. A visitor who steps off floor 1's
open north edge there would be treated as flying by `game.gd:421` and `walker.gd:44`, in
an invisible box, instead of falling. The roof has its edge rail; floor 1 has none.

**Proposed hook** (shared; Codex's call; the museum's zones are live whenever they are
used):

```gdscript
static func at_point(tree: SceneTree, world_position: Vector3) -> Node3D:
	for zone in tree.get_nodes_in_group(GROUP):
		if zone.is_visible_in_tree() and zone.can_process() and zone.contains_point(world_position): return zone
	return null
```

A trial-scoped alternative, if Codex prefers it, is the same guard inside the walker
and `game.gd` calls for noise_02 only.

## Not requested

- **Editor markers.** None needed: all 17 sources build geometry.
- **Layout changes.** None. `layout.json` (42 x 32 m, 6 m storeys, both shafts, all
  columns, default sign positions) is untouched.
- **Fit.** The oversize works are curation questions, not shared fixes. Listed under
  "Open" in HANDOFF.md and STATUS.json.
