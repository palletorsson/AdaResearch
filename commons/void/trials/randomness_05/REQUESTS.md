# randomness_05: shared-code requests (Claude worker B, batch 25)

All requests are trial-scoped to `randomness_05`. No source file, shared script or other
trial was edited. Evidence is **static** (source reading) unless a native run is cited.
The probe's checks that depend on a request say so in their names: `(needs R1)` and so on.

**Final state (21 Oct).** Full native 257/257 (desktop and synthetic XR, no engine
errors), export 64 models, editor 29/29. Awaiting Codex review, not accepted.
- R1–R4 are wired by Codex in `floor_content.gd`, scoped to randomness_05, and verified
  natively. Details are in HANDOFF.md.
- R5 stays documented: not lethal, no new behaviour.
- R6 stays documented as missing support. No guessed pedestal will be installed.
- **Exit leak.** The bounds-1..5 runs all ended with the same leak report. It is
  diagnosed and fixed inside my already-wired `sculpt_one_local.gd`; no new hook is needed
  (see R4b).

| | What | Kind | Adapter / file |
|---|---|---|---|
| R1 | museum exhibit staging (glass box, compact console) | hook | existing `museum_exhibit_stage.gd` |
| R2 | arena: configure before `_ready`, recognise the Void body | hook | existing `commons/void/removal_arena_local.gd` |
| R3 | falling field: launch under the slab above, debug keys off | hook | `randomness_05/cube_field_local.gd` (mine) |
| R4 | env_one / sculpt_one: re-hide suns after a seed rebuild | hook | `randomness_05/env_one_local.gd`, `sculpt_one_local.gd` (mine) |
| R5 | fire jets and basins are not lethal in the Void | decision | none |
| R6 | the museum's `#plinth:H` pedestals are not built | optional hook | none |

## R1. Exhibit staging for the `controls:compact` / `glass_*` tokens (static)

The museum installs `museum_exhibit_stage.gd` on every stamped body
(`endless_museum.gd:13363`). `install()` acts only when the config has `glass_width` or
`controls: compact`. In the Void only `randomness_02` gets it (`floor_content.gd:444`).
Six placements here carry those keys:

- `f2_monte_carlo_dartboard_4_12`;
- `f5_r_c_9_6` (`control_front:-2.6 control_height:1.38 control_floor:0.28 control_fixed:true`);
- `f5_random_removal_arena_9_17` (`glass_width:11 glass_depth:11 glass_height:4.5 glass_title:THE SET UNDERFOOT glass_grid:false`);
- `f5_random_doors_9_29`, `f5_cube_projectile_spawner_9_51`, `f5_waiting_profile_9_61`.

Without the hook the arena has no glass enclosure, and the five rack panels stay where each
script built them, not on the museum's reach console. Monte Carlo is unaffected in
practice: its `lesson:sample_budget` console has no `panel_w` meta, so `_compact_controls`
finds nothing to move.

**Hook** (`floor_content.gd:444`):

```gdscript
if trial_id in ["randomness_02", "randomness_05"]:
	preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd").install(artifact, source_config)
```

## R2. Random_Game's arena: configure before `_ready`, and the Void body (static)

The same two faults as randomness_03 R1/R2, now with `columns:9 rows:9`:

- `removal_arena.gd` builds the tiles in `_ready()` and reads `rows` only in
  `apply_grid_config()`. Configured after `_ready`, it builds the default 9 x **11** = 99
  tiles, not the source's 9 x 9 = **81** over the 9 x 9 basin.
- `is_player()` accepts only group `player` when there is no museum, and the Void body is in
  `player_body`. Walking onto the floor would withdraw nothing.

**Hook:** extend both existing randomness_03 branches:

```gdscript
if trial_id in ["randomness_03", "randomness_05"] and item.artifact == "random_removal_arena":
	artifact.set_script(preload("res://commons/void/removal_arena_local.gd"))
# ...
if trial_id in ["randomness_03", "randomness_05"] and item.artifact == "random_removal_arena":
	before_ready = true
```

`removal_arena.tscn` has no exported overrides on its root.

## R3. The falling field launches 8 m up, above the next slab (static)

`cube_projectile_spawner#mode:field#field_height:8...` launches each cube at
`global_position.y + 8`. A Void storey is 6 m with a 0.36 m slab, so the launch point is
about 2 m above floor 4's slab. `ProjectileCube` collides with layer 1 and has no contact
monitor, so a cube lands on floor 4 and lies there for its 10 s lifetime. Floor 5's field
would stay empty.

The source also has `_input` debug keys: P (toggle), O (one cube), C (clear). C is the
Void's desktop hands-together key (`desktop_hand.gd:72`). RUN / STOP and CLEAR are already
on the field-stand panel.

**Adapter:** `commons/void/trials/randomness_05/cube_field_local.gd`
(`extends CubeSpawner.gd`). It does three things:
- keeps every source value, including `source_field_height = 8`;
- caps only the launch height: under the slab above the spawner's own floor (clear height
  − 0.25 m cube − 0.2 m margin, about 5.2 m), recomputed at each launch from the floor root,
  so it stays right after a move and at any depth (no floor root, no cap);
- disables `_input`.

The original readout then reports the height actually used.

**This is an effective-height adaptation, not unchanged behaviour.**
- Cubes start about 5.2 m up instead of 8 m, so each fall takes about 2–3 s instead of
  3–5 s.
- The configured 8 m stays as `source_field_height`.
- The cap is measured from the field origin: spawner plus `field_center_offset`, including
  `.y` (fixed after Codex's note; the token has no offset).

Focused cases:
- `field`: real source spawns launch under the slab, and a cube comes to rest on floor 5.
- `fieldmove`: the mount raised 1 m, then moved 2.5 m and turned 90°, then offset +0.6 m
  in y.
- `fieldsleep`: residency. The projectiles are children of the current scene, not of
  floor 5. The case measures that the emitter sleeps and launches nothing while the
  visitor is away. It also measures whether cubes already in flight expire within their
  10 s lifetime.

**Hook** (before `add_child`; the scene overrides `spawn_interval = 6.0` and
`max_projectiles = 4`, so keep the exported values across the swap):

```gdscript
if trial_id == "randomness_05" and item.artifact == "cube_projectile_spawner":
	var field_settings: Dictionary = {}
	for property in artifact.get_property_list():
		if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
			field_settings[property.name] = artifact.get(property.name)
	artifact.set_script(preload("res://commons/void/trials/randomness_05/cube_field_local.gd"))
	for key in field_settings: artifact.set(key, field_settings[key])
```

Not done instead: shrinking or moving the field. Its 8 x 8 m region is larger than a shaft
opening, so it cannot sit under one.

## R4. Seed consoles rebuild a WorldEnvironment and unscoped suns (static)

`env_one` (`envOne.gd:1400 apply_lighting`) and `sculpt_one` (`SculptOne.gd:132
setup_environment`) build their own WorldEnvironment and DirectionalLight3D (sculpt_one:
two suns, energy 2.0 and 1.0). `floor_content.gd:463-470` neutralises them once, after
`add_child`. Both tokens ask for `seed_controls:true`, and every console press rebuilds:
- `art_seed_controls._press` → `set_generation_seed`;
- `env_one` → `apply_lighting()`; `sculpt_one` → `_rebuild_now` → `setup_environment()`.

So a fresh environment and visible suns come back, and a DirectionalLight3D lights every
floor of the tower. The visitor camera carries its own environment (`game.gd:226`), so the
environment matters less than the suns.

**Adapters** (mine): `env_one_local.gd` overrides `apply_lighting()` and
`sculpt_one_local.gd` overrides `setup_environment()`. Each calls the original, then applies
floor_content's own import rule again: environment null, suns hidden. Neither scene has
exported overrides on its root.

**Hook:**

```gdscript
if trial_id == "randomness_05" and item.artifact == "env_one":
	artifact.set_script(preload("res://commons/void/trials/randomness_05/env_one_local.gd"))
if trial_id == "randomness_05" and item.artifact == "sculpt_one":
	artifact.set_script(preload("res://commons/void/trials/randomness_05/sculpt_one_local.gd"))
```

### R4b. Exit leak in `SculptOne.create_fluid_mass` (diagnosed; fixed inside my adapter)

**Measured symptom** (coordinator, bounds-1..5, desktop). Every run passed its checks, then
failed at exit with the same report:
- "ObjectDB instances leaked at exit";
- 2 RenderingServer Instances, 2 Meshes, 2 Materials and 1 Shader;
- "Leaked instance dependency".

Floor 1, the start floor, is built in every run, so the cause had to be floor-1 content.

**Cause** (static, and it matches the count exactly). `SculptOne.gd:411` creates
`base_mesh = MeshInstance3D.new()`: a SphereMesh scaled by `scale_vec`, with the material
override. It is never added to `fluid` and never freed. The default `composition` hand
calls `create_fluid_mass` twice: the base block (`glossy_purple`) and the red blob
(`glossy_red`). That gives:
- 2 MeshInstance3D: 2 RS instances;
- 2 SphereMesh;
- 2 StandardMaterial3D, both clearcoat, sharing 1 RS shader.

Each seed rebuild would leak two more. The museum has the same source fault. No other
unparented node was found in the floor-1 and floor-2 scripts (scan of every `*.new()` that
is never `add_child`ed or returned).

**Fix (trial-only).** `sculpt_one_local.gd` (already selected by Codex's R4 hook) overrides
`create_fluid_mass` with the source body minus the orphan. The orphan used no random draws,
so the drawn sculpture and the seed's result are unchanged, and nothing visible changes:
the orphan was never shown.

**Verify.** Run the focused case `orphans` (floor 1). It prints `Node.print_orphan_nodes()`
before and after a real sculpture rebuild. env_one's ten module templates are orphans by
design (freed in its `_exit_tree`); they are not part of the leak. Then rerun `bounds-1`:
it should exit with no leak lines.

## R5. Not lethal in the Void: fire jets and basins (decision, not requested)

- `random_doors._burn` calls `museum._basin_burned(body)`. With no museum ancestor
  (`museum == null`) it does nothing. In the Void a fire jet is a visual.
- The museum plan gives Random_Game `basin: {depth: 3, glass: false, fire: true,
  fire_top: -2.3}`. The Void basin (floor 5: r_c pit and arena basin) builds a bottom and
  walls but no fire. This is the same as randomness_03 R3.

A fall from the arena lands 3 m down and needs retry (B). A fall from the crossing lands on
r_c's own bed 1.02 m down, and its WayOut ramp climbs back. If either should end the run,
that is a shared `basin.gd` / `game.gd` change: Palle's call.

## R6. `#plinth:H` pedestals are not built (optional)

`noise_mixer#plinth:0.9`, `worley_noise#plinth:0.4` and `shannon_entropy_meter#plinth:1.05`
(floor 4) stand on a station plinth of that height in the museum (`endless_museum.gd:13247`,
"the plinth IS the height claim"). Each is placed at that height here and floats with no
support. The same pattern as the `OriginalHallPedestal` at `floor_content.gd:411` would
reattach one, as a child of the exhibit. Place it after `mount.add_child(artifact)`, next
to that line:

```gdscript
if trial_id == "randomness_05" and float(str(item.get("config",{}).get("plinth","0"))) > 0.05 and float(item.get("height",0)) > 0.05:
	var lift := float(item.height)
	preload("res://commons/artifacts/rotation_studies/parts.gd").box(artifact,"OriginalHallPlinth",Vector3(0.9,lift,0.9),Vector3(0,lift/2.0-lift,0),Color("e9e4d8"))
```

Until then: recorded as missing support. **Codex (20:31):** R6 stays documented missing
support, pending review of the original plinth geometry. Do not install a guessed generic
pedestal as an original artifact. The hook above is not requested.
