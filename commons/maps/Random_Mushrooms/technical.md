# Random_Mushrooms - Technical Documentation

## The primary: `mushrooms`

`algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd` (Node3D, built in `_ready`). The build is one pass, in this order, and it is an arrangement made once: nothing grows, moves or spawns afterwards.

1. **The ground.** A `meadow_size` × `meadow_size` plane at `ground_resolution` (36) cells, its vertex heights drawn by `ground_rng` within ±`ground_random_amplitude` (0.18 m), a trimesh collider from the same mesh (`Ground/GroundStaticBody/GroundCollision`). `get_ground_height(x, z)` bilinearly interpolates the height grid, and every mushroom is set down at the ground's height.
2. **Six templates.** `create_mushroom_template(i)` for `i` in `mushroom_variety` (5): a tan cap, a red cap with spots, a flat brown cap with gills, a tall white one, a puffball with bumps; then `create_glowing_mushroom()` (a green stem, an emissive cap and an `OmniLight3D` named `GlowLight`). The templates are Node3Ds that never enter the tree.
3. **Candidates.** `generate_mushroom_positions()` draws `target_count = mushroom_count × mushroom_density` (100 × 0.8 = 80) uniform positions in the square, evaluates a `FastNoiseLite` (seeded by a draw, frequency 0.5) at twice the position, and refuses any candidate under −0.3. The refused positions are kept in `_rejected`.
4. **The scattered field.** For each accepted position: a template by `_ri() % 6` (the glowing one re-drawn against `glowing_mushroom_spawn_chance` 0.32), a copy by `duplicate()`, a yaw `_rf() * 360`, a uniform scale `_size(0.7 + _rf() * 0.6)`. Metadata `template` and `kind = "scattered"` on the instance.
5. **Rings.** `int(meadow_size / 5)` fairy rings, each a centre, a radius `1.0 + _rf() * 2.0`, one template (never the glowing one), `int(radius * 8)` members at equal angles; a member outside the square is skipped. Scale `_size(0.8 + _rf() * 0.4)`; metadata `kind = "ring"`, `group`. Each ring records `requested` and `placed`.
6. **Clusters.** `int(meadow_size / 3)` clusters, each a centre, a spread `0.5 + _rf() * 1.0`, `5 + _ri() % 10` members at random angle and distance, one template (the glowing one allowed); scale `_size(0.5 + _rf() * 0.7)`; `kind = "cluster"`.
7. **Lighting and cover.** A `DirectionalLight3D`, a `WorldEnvironment` with fog, then `Grass` (a MultiMesh of blades), `Rocks` (three MultiMeshes) and `FallenLeaves` (a MultiMesh), all drawn from the same stream.

### The draws

Every draw of the build goes through two functions; there is no other call to a random source in the file:

```gdscript
func _rf() -> float:
	return _pop_rng.randf() if _pop_rng != null else randf()

func _ri() -> int:
	return _pop_rng.randi() if _pop_rng != null else randi()
```

`population_seed` is −1 by default: `_pop_rng` is null and the calls fall through to the global `randf()` / `randi()`, the same call in the same order as the shipped file, so the shipped meadow is unchanged. Under a non-negative seed a private `RandomNumberGenerator` makes every draw, and `ground_rng` takes `population_seed + 1` unless `ground_seed` is set. `regrow()` frees the field, the ground, the templates and the cover and rebuilds them in the build's order, so a seeded regrow returns every instance's template, kind, position, yaw and scale and the same ground heights (a probe compares the full instance list and a hash of the height grid, not the seed).

### The size rule

```gdscript
func _size(v: float) -> float:
	return v if size_variation else 1.0
```

The draw is made whether or not the rule is on, so switching `size_variation` under the same seed changes every scale to 1 and nothing else.

### The specimen table (`stand:specimen`, opt-in)

`stand` is an export enum `none | specimen`, default none. Under `specimen`, `_prepare_stand()` runs before the first build: a five-digit `population_seed` from a private generator if none was given, `max_glow_lights` 12 if 0, `bed_lift` = `ground_random_amplitude` if 0. After the build:

- `_lift_bed()` raises `Ground`, `MushroomField`, `Grass`, `Rocks` and `FallenLeaves` by `bed_lift`, so a ground that undulates ±0.18 around 0 stands on a floor at 0 rather than being cut by it; `_build_kerb()` boards the bed's four sides at the ground's highest reach.
- `_build_table()` stands a 1.5 × 0.5 × 0.9 m body at `+z` = half the bed plus a 0.9 m gap (the map token is rotated 180° so this edge faces the door), with a `StaticBody3D` collider, six discs and numbered tags along the top, a stencil, a 0.78 × 0.15 m plate leaning back 12° carrying a six-line `Label3D` at 0.95 mm per pixel, and a `RackTemplates.create_panel` with SHOW · KIND · SIZE / REGROW · NEW SEED at 32°. Each `Btn_N/InteractableAreaButton.button_pressed(button)` is connected to a one-argument lambda (the signal carries the button; a zero-argument method is refused at emit).
- `_refresh_specimens()` duplicates the six templates onto the discs at scale 0.8 (the glowing specimen's light off), again after every regrow.
- `_refresh_highlight()` fills two `MultiMeshInstance3D`s, a torus outline wider than a cap (radii 0.23–0.28) on the ground 4 cm over the instance's own ground height plus the lift, and a pin (a 4.5 cm sphere) 0.75 m above it (0.35 m for a rejected candidate), unshaded and vertex-coloured: magenta for every instance of the shown template (and a ring on that template's disc on the table), deep blue for every scattered instance, green for ring members, violet for cluster members, dark grey for rejected candidates (saturated since the visual pass of 12 September: pale marks competed with the caps and grass). The disc numbers are 3.3 cm.
- `readout_lines()`: the seed and REGROW's policy; candidates, accepted, rejected; rings (placed), clusters (placed), templates; the SHOW or KIND line with its count; the size rule or SIZE off; glow instances, lit lights of the cap, mushrooms. Lines ≤ 46 characters.
- `_note_light()` counts glowing instances and switches off the `OmniLight3D` of any past `max_glow_lights` (the cap keeps its emissive material).
- `_exit_tree()` frees the templates, which never entered the tree (51 objects leaked at exit before this, measured 2026-09-12).

API for probes and other callers: `regrow()`, `new_seed()`, `set_population_seed(v)`, `set_size_variation(on)`, `show_template(i)`, `cycle_show()`, `set_kind(i)`, `cycle_kind()`, `instances()`, `ground_signature()`, `readout_lines()`, `highlighted_count()`, `get_specimen_state()`.

### The edible ones (`edible`, opt-in; Palle, 12 September)

`edible` is a word-valued export enum `none | some | many` (3 or 6; `#edible:some` in this map's token) read by `apply_grid_config`. `_plant_edibles()` runs after the whole build (and after every regrow): its draws come last on the same generator, so the population is exactly what it is without them and REGROW plants them at the same places; NEW SEED elsewhere. Each is an instance of `res://commons/hazards/mushroom/edible_mushroom.tscn` (`EdibleMushroom extends XRToolsPickable`, a RigidBody3D on the pickable layer) at `mushroom_scale` 1.5, planted still (frozen) at the ground's height plus the lift, a third of a metre inside the local +x or −z kerb in turn — under the token's 180° turn the west and south margins, where the walk runs. `edibles_state()` reports planted, present, eaten and both the planted and the settled positions; the plate's last line counts the ones still standing (`glow 6 · lit 6/12 · mushrooms 104 · edible 3`), refreshed by a one-second watch because an eaten mushroom dissolves without a signal. Eating is the artifact's own rule: held within 0.25 m of the camera (a headset brings it to the face) it heals five percent, triggers a `MushroomEffect` (a screen shader for ten seconds) and dissolves. The desktop pointer carries it at a metre or more, so on desktop it can be picked up and put down but not eaten by that rule; the live probe calls the eat as the desktop stand-in and says so.

### Map configuration

`apply_grid_config` reads `size` (the bed's side in metres; a whitelisted key), `count`, `density`, `seed` and `stand`. The museum hands the config before `_ready`, so the values are stored and the first build uses them; the grid hands it after, and a built meadow regrows. The Random_Mushrooms token:

```
mushrooms:180#stand:specimen#size:6#edible:some
```

A six-metre bed at cell (6,7) with its table at the north edge facing the north door, its own seed each run, three edible mushrooms at its reachable edges. `#seed:NNNNN` pins one.

## The hall

13 × 13 cells; the interior x 1..10 at floor level with a one-metre platform strip along x 11 (rows 3–9; the 10 September recovery); the north door three cells wide at x 5–7, the south door at (6,12), the teleporter at (8,12). Museum block: `wall_height 3`, `gate_depth_rows 0`, `artifact_placement map` (the map's cells are final; the dealt lane neither slides nor shrinks a body), `sculpture_clear_rects [[3,1,10,12]]` (cells 3–9 × 1–11 kept free of dealt plinths; the far edge is exclusive), `floor_cells [[8,12]]` (the teleporter's void cell floored in the museum; the grid keeps its `0`).

Tokens: `mushrooms:180#stand:specimen#size:6` (6,7); `dark_sphere` (10,2); `bubbles_random:0:-0.5:1.0` (10,4); `random_number_book_page_collection:0:1` (10,7); `bubble_particles:0:-0.5` (10,9); `reaction_diffusion_intro:0:-0.5` (9,11). The bed spans x 3.5–9.5, z 4.5–10.5; the table's face is at z ≈ 3.1 and the visitor's spot at (6.5, 2.3); the walk runs from the north door down the west margin (x 1–3.5) and along the south margin (z 10.5–12) to the south door.

## Measured

See `field_notes.md` for the runtime pass (both lanes) and `ada_run/waves_chance_noise/Random_Mushrooms/report.md`.

## Failure modes worth naming

A ring whose centre falls near the kerb is an arc, and the plate's bracket says how many of its members were placed. The clusters' members can land on top of scattered mushrooms; nothing prevents overlap, and nothing in the scene claims to. The glow cap is a count of lights, not of glowing caps: past twelve, a glowing mushroom keeps its emissive cap and loses its light. Under the shipped default (no seed) REGROW is a new population, and the plate says so.
