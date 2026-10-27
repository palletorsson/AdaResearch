# Rhizome Network (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**
Static checks: `floor-2.json` substituted into this trial's `rooms.json` in memory
validates against `rooms.schema.json`. All three IDs appear once with their `#` configs.

## Placement

The source hall (31 x 37) is turned 180°: `x = 15 - cell_x`, `z = 12 - cell_z`,
`facing = source rotation + 180`. The entrance (15,1) lands at the arrival (0, 12).

| id | at | facing | height | config | note |
|---|---|---|---|---|---|
| `f2_rhizome_grower_4_2` | 11, 10 | 0 | 0 | interactive, spread 0.85, grow_period 0.8, sample_seed 47 | rigid |
| `f2_film_rhizome_routes_1_15` | 14, **-5.5** | 270 | 0 | plinth 0, pin true | rigid z -3 |
| `f2_rhizome_cave_demo_15_18` | **0, -29.85** | 180 | 0.025 | passage_study | rigid (0, -6) |

## Cave size and the fit exception

With `passage_study` true, `RhizomeCaveDemoController.gd` `_start_passages()` builds
`rhizome/RhizomePassages.gd`. That is a fixed graph of 15 junctions and 20 links (x ±11,
z ±14). Each link is carved by `_carve_passage()` as a tube 1.65 m in radius plus a
0.24 m wall. Its floor is flat at the junction height and its interior is 3.27 m high.
`_double_surface()` cuts both portals at local |z| ≥ 13.85.

| measure | value |
|---|---|
| Footprint | **25.8 x 27.7 m** (x ±12.9, z ±13.85) |
| Height | **-0.22 to 7.26 m**; the upper crossing's floor is at 3.7 m, its roof at 7.26 m |

**It does not fit on a Void floor, so it is not shrunk.** I searched all four facings and
every 0.5 m offset that keeps it on the slab (612 positions). In every one, at least one
tube centreline passes through a shaft hole. The rigid position (0, -6) puts tubes
through both shafts and shaft B's pad. Its upper crossing also passes through the floor-1
slab: the roof is 7.26 m against a ceiling of about 5.64 m. A taller storey would not
free the shafts.

**Proposed separate specimen placement (in `floor-2.json`).** Centre (0, -29.85), facing
180, which is the rigid turn's facing. The cave stands south of the tower, x -12.9..12.9,
z -43.7..-16.0. Its local -z portal, the source's entrance end, lands exactly on the slab
edge at z -16, with the passage floor at +0.025 m flush with the slab. Nothing of the
tower is above or below it, so the 7.26 m crossing is open to the sky, and both shafts
and the arrival stay untouched. The cave's own `WalkableShell` (a trimesh with backface
collision) is the floor.

**Required adapter for this placement (not written; this batch allows two files).**
`game.gd` treats |z| > 19 as "Fell beyond the building" unless the collider under the
feet belongs to `void_exterior_walk` (`_exterior_walk_support`). Without the adapter a
visitor can enter only about 3 m. The Scale chamber already uses this group.

```gdscript
extends "res://algorithms/spacetopology/marchingcubes/scenes/RhizomeCaveDemoController.gd"
## Exterior specimen: the passage shell is real support beyond the tower slab.
func _ready() -> void:
	add_to_group("void_exterior_walk")
	super._ready()
```

Add an inherited scene of `rhizome_cave_demo.tscn` (root `RhizomeCaveDemo`) with this
script, plus a catalog `scene` override for `rhizome_cave_demo`. No floor-extension region
is needed: the visitor stays at floor-2 height.

## Interactions (handler bodies read)

- **`rhizome_grower` (`commons/artifacts/rhizome_grower/rhizome_grower.gd`), working.**
  - With `interactive` true, `_build_controls()` makes the CONNECTIONS panel. Its
    buttons call `_operate(_body, i)`:
    - 0 GROW pauses or resumes, only while no node is cut.
    - 1 STEP adds one shoot (`_grow_shoot`).
    - 2 LINKS toggles one or three links per arrival (`_rewire`).
    - 3 NODE selects the next node.
    - 4 CUT toggles that node.
    - 5 REPLAY rebuilds from the stored samples.

    Readouts are `_refresh_graph()`: degrees and components.
  - Config is read only in `apply_grid_config()`, which rebuilds. `_ready()` first builds
    a randomised non-interactive grower, and the config call then rebuilds it seeded 47
    and interactive. *Optional:* catalog `configure_before_ready` for a single build.
- **`film_rhizome_routes`, working.** `concept_monitor.gd` buttons call `film_stage.gd`:
  PAUSE `toggle_pause()`, REPLAY `replay()`, STEP `step_sample()`, TURN VIEW
  `next_route()`. `rhizome_routes.gd` overrides none of them. It activates on gaze
  within 14 m.
- **`rhizome_cave_demo`, walk-through only.** It has no controls. It has three coloured
  junction lights with rings at points 3, 4 and 7, and four lamps on the upper route.
  `_enter_tree()` removes the demo `Environment` and `Camera3D` when the
  `config_passage_study` meta is present; the Void stamps it before `add_child`.
  `build_passages()` loads the tracked `rhizome_passages_mesh.res` (2.4 MB) if its
  `source_signature` matches the two scripts' SHA-256. Otherwise it regenerates the
  65 x 24 x 71 field asynchronously.

## Film shift (fit reason)

At the rigid (14, -3), facing 270, the screen faces -x and its viewing spot (x about 13)
is on shaft B's east lip. At z -5.5 the film and its viewer are 1.15 m south of the hole.
Its x and facing are unchanged.

## Focused checks (shared probe helpers)

```gdscript
if level == 2:
	var g: Node3D = station("f2_rhizome_grower_4_2")
	check(tag+"grower seeded and interactive", g.interactive and g.sample_seed==47 and g._controls != null)
	await approach(g, 1.8)
	await press(g._controls.find_child("Btn_2",true,false))   # LINKS
	check(tag+"LINKS toggles to one link", g.links_per_node==1)
	var cave: Node3D = station("f2_rhizome_cave_demo_15_18")
	var p: Node = cave.get_node("InhabitableRhizome")
	for i in 240:
		if p.ready_to_walk: break
		await frames(1)
	check(tag+"cave shell ready, demo camera/env removed", p.ready_to_walk and not cave.has_node("Camera3D") and not cave.has_node("Environment"))
	# with the exterior adapter: walk in through the portal past z -19 without dying
	var deaths: int = game.deaths
	game.place_player(cave.to_global(Vector3(0,0.06,-3))); await frames(90)   # junction 4 (blue light), world z -26.85
	check(tag+"cave interior is supported outside the slab", game.deaths==deaths and not game.recovering)
```

## Dependencies

- The exterior-walk adapter and catalog override above are **required** for walking the
  cave at this placement.
- If the cached mesh signature is stale, the first visit regenerates the cave
  asynchronously, at an unmeasured cost.
- There are seven OmniLights in the cave, as authored for Mobile's per-mesh light budget.
- An editor or exporter may clamp or flag positions off the slab; this one is deliberate.
