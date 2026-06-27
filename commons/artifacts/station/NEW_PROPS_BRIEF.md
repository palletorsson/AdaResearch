# New Station Props — the five kinds orthogonal to "an object on a base"

The station kit (plinth/micropod/stage/panel/pillar/cabinet/barrier/bench/crates) is entirely
*"a solid object that sits on a floor and holds ONE thing."* Curating 20 walls surfaced a small,
nameable set of asks the kit structurally **cannot** express as a config of those — they are the
things that aren't an-object-on-a-base: **light, the floor as a relation, sky/atmosphere, passage,
and a surface that shows many.** Build them as first-class members of the same family.

## Shared contract (study `commons/artifacts/station/station_plinth.gd` — match it exactly)
- `extends Node3D`, `class_name <PascalCase>`. `const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")` — use its materials (`rams_body`, `worn_metal`, `emissive`, `readout`, `signage`, `three_color_bar`, `grime_band`) so the new props read as the SAME painted-metal Rams family.
- A full `# @identity` block at the top (essence / desire / critical_parameter / triggers / emerges / needs / relationships / truth) — the prop's *meaning*, in the voice of `station_plinth.gd` lines 6-14. The `relationships` line should link `[[station_plinth]]` etc.
- `@export` vars grouped by `@export_group`. `func apply_grid_config(config_data: Dictionary)` that writes each key to `set_meta("config_%s" % k, v)`, then `_read_metadata_overrides()`, then rebuilds (free children + `_build()`). `func _read_metadata_overrides()` reads every `config_<key>` meta back onto the export. `_ready()` = `_read_metadata_overrides()` + `_build()`.
- **Build procedurally in `_build()`**, origin at the FLOOR CENTRE (so spawning at y=0 seats it correctly — the wall editor places at the JSON x/y/z with no grounding). Snap to the 1 m grid where size is in cells.
- **Colors passed via config are STRINGS** `"r,g,b,a"` (the grid string-coerces config; a typed Color breaks the parser). Provide a `_pc(s, fallback)` parser like the plinth's.
- Keep it light: a handful of `BoxMesh`/`CylinderMesh` `MeshInstance3D`s + at most one real `Light3D`. No per-frame work.

## Output (per agent — write exactly these three, touch nothing else)
1. `commons/artifacts/station/<token>.gd`
2. `commons/artifacts/station/<token>.tscn`  — `[gd_scene load_steps=2 format=3]` + ext_resource the .gd + a root Node3D named `<PascalCase>` with `script = ExtResource("1")` (set any non-default @export values here if the scene is a preset).
3. `commons/artifacts/station/_pending/<token>.json`  — the registry entry object (create the `_pending/` dir), shaped EXACTLY like the `station_plinth` entry in `commons/artifacts/registry/station.json` (`lookup_name, scene, class_name, name, description, category:"station", complexity:"beginner", include_in_map_data:true, map_ready:true, tags:[…], parameters:{…}, spatial_needs:{footprint_cells, platform}`).

Verify: `& "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --headless --xr-mode off --quit-after 60 res://commons/artifacts/station/<token>.tscn`, then scan the newest `%APPDATA%/Godot/app_userdata/Ada Research Zero One/logs/*.log` for `SCRIPT ERROR|Parse Error` (the only acceptable noise is benign "Unrecognized UID" / NatureRenderer warnings). Confirm your `<token>` is NOT already present in any `commons/artifacts/registry/*.json`.

---

## The five (one agent each)

### 1. `station_luminaire` (StationLuminaire) — LIGHT
The kit's only source of light: a painted-metal fixture + a real `Light3D`. It says *this one* by lighting it. Two modes via config `mode`: **"task"** = an aimed `SpotLight3D` on an arm/gooseneck over a focal bay; **"area"** = a soft `OmniLight3D` in a hung housing. Config: `mode` (task|area), `height` (mount height, m), `intensity`, `light_color` ("r,g,b,a"), `warm` (bool), `arm_reach`. Origin at floor; for "area" it can hang (a thin drop-rod from `height`). @identity desire ≈ *"to throw attention onto one thing — the kit's first piece that acts on the others, not beside them."*

### 2. `station_floorline` (StationFloorline) — THE FLOOR AS A RELATION
A FLUSH floor element (y ≈ 0, ~2 cm proud) that *connects* rather than isolates: a lit strip / processional stripe / threshold you read with your feet. Config: `length_cells`, `width` (m, ~0.2–0.6), `style` (line|path|threshold), `direction` (0/1/-1 → chevrons pointing along +X / none / -X), `accent_color`. "threshold" = a wider bar with end ticks; "path" = a dashed runner with directional chevrons. This is the kit's first piece about *between*, not *on*. @identity desire ≈ *"to join two places — the ground made to point."*

### 3. `station_skydome` (StationSkydome) — ATMOSPHERE, NOT AN OBJECT
A large unlit/emissive BACKDROP for artifacts that have no scale (the `dark_sphere`/`fractal_clouds` the curators had to float base-free): an inward-facing curved shell or tall bowed plane set BEHIND a bay as void/sky. Config: `width_cells`, `height` (m), `mode` (void|sky|gradient), `top_color`/`bottom_color` ("r,g,b,a") for a vertical gradient (a tall quad with a gradient emissive material, or two stacked bands), `depth_offset` (how far back, −Z). Unlit (`shaded=false`/emissive) so it reads as air, never a surface. @identity desire ≈ *"to be the air behind everything — where a thing has no edge, give it a sky."*

### 4. `station_ascent` (StationAscent) — PASSAGE
The kit's first piece about *getting there*: a way up onto a tall stage / between heights. Config: `rise` (height to climb, m), `style` (stair|ladder|ramp), `width` (m), `handrail` (bool). "stair" = a flight of treads sized to `rise`; "ladder" = two stiles + rungs; "ramp" = an inclined deck. Painted-metal + worn treads + an emissive nosing line. Origin at the foot. @identity desire ≈ *"to be climbed — the only station piece that admits the body must move to see."*

### 5. `station_multiscreen` (StationMultiscreen) — SHOW MANY AT ONCE
A wall-mounted (z ≈ 0.06, `wall:true` when placed) framed panel divided into an R×C GRID of sub-screens, each a 2D-in-3D `readout` cell with its own little caption — for the "four-views / convergence" capstones one `station_panel` can't hold. Config: `rows`, `cols`, `cell_labels` (array of strings, one per cell, row-major), `header` (string), `panel_w`/`panel_h` (m), `accent_color`. Reuse `HangarKit.readout` per cell inside a shared bezel frame. @identity desire ≈ *"to show that several faces are one idea — the panel that holds a convergence."*
