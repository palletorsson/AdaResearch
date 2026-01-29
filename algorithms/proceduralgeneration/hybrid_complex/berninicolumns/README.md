# Melting Bernini Columns

A high-drama procedural sculpture that melts Gian Lorenzo Bernini's baroque column vocabulary into fluid, queer geometries. The Godot 4 demo generates all column meshes on the fly, keeps the capitals and plinths intact during animation, and exposes tuning controls for VR-friendly exploration.

## Scene Assets
- `MeltingBerniniScene.tscn` — loads the procedural controller and lighting rig.
- `MeltingBerniniColumns.gd` — main generator with mesh synthesis, material creation, and runtime animation.
- `berninicolumns_tutorial.gd` — BBCode tutorial card surfaced in game.
- `code_prompt.txt` — reference instructions for regenerating the script with an AI assistant.
- `meta.json` — metadata for VR menus, search, and topic catalogs.

## How It Works
1. `_ready()` samples a five-point cross layout, picks a palette color (or falls back to `material_color`), and calls `create_spiral_column()` for each entry.
2. `create_spiral_column()` returns a dictionary describing the Node3D wrapper, shaft mesh, base, capital, material, and base melt phase so later updates do not rebuild the full hierarchy.
3. `generate_spiral_column_mesh()` builds the shaft with SurfaceTool, layering spiral offsets, ribbing, overhangs, chaotic noise, and melt compression before committing the mesh.
4. `create_shaft_material()` prefers the new procedural marble shader (`res://algorithms/proceduralgeneration/berninicolumns/shaders/marble_column.gdshader`), falling back to the displacement shader or a generated normal map when disabled or unavailable.
5. `_process()` rotates pillars (when enabled), streams the marble shader's `u_time` uniform, and drives `update_column_mesh()` which lerps the melt phase and simply swaps the shaft mesh while preserving material and child nodes.

## Exported Controls (Godot Inspector)
| Property | Default | Description |
|----------|---------|-------------|
| `column_height` | `10.0` | World-space height of each shaft before melting offsets. |
| `column_radius` | `0.5` | Base radius used before ribs and chaos modify the profile. |
| `spiral_density` | `5.0` | Number of twists carved into the spline path. |
| `sine_amplitude` / `cosine_amplitude` | `0.4` | Orthogonal wave amplitudes for the spiral center offsets. |
| `vertical_segments` / `radial_segments` | `80` / `24` | Mesh resolution for the SurfaceTool sweep. |
| `twist_factor` | `2.5` | Additional axial rotation applied while lofting vertices. |
| `melt_strength` | `1.5` | Controls how aggressively the column compresses downward. |
| `overhang_factor` | `0.8` | Adds leaning drips and asymmetry near the top. |
| `bulge_amplitude` | `0.6` | Modulates radial bulging along the height. |
| `chaos_factor` | `0.3` | Injects sine-based micro-noise for organic irregularities. |
| `rib_count` / `rib_depth` / `rib_sharpness` | `12` / `0.15` / `2.0` | Define the number, depth, and profile of the baroque flutes. |
| `rotate_columns` / `rotation_speed` | `true` / `0.15` | Enables motion and sets the base angular speed. |
| `animate_melting` / `melt_speed` | `true` / `0.3` | Toggles the melt loop and its temporal frequency. |
| `use_marble_shader` | `true` | Enables the procedural marble shader; disable to revert to the displacement/standard materials. |
| `marble_*` | see inspector | Vein contrast/strength, noise scale, turbulence, swirl, timing, emission, and surface response for the marble look. |

## Runtime Flow
- Dictionaries stored in `columns` drive animation without destroying nodes each frame.
- `base_melt_phase` keeps a per-column anchor so the lerp maintains unique silhouettes.
- Lighting mixes a warm directional key with colored spotlights positioned above each pillar for theatrical shadows.
- Marble shader uniforms animate smoothly because `u_time` is refreshed every frame before the mesh regeneration step.
- A low, metallic platform grounds the composition and avoids horizon floats in VR.

## VR & Performance Notes
- Five columns at 80×24 resolution mesh cleanly on Quest-class hardware; bump segments cautiously.
- Disable `rotate_columns` and/or drop `melt_speed` in comfort-first showings.
- Shader displacement is more expensive than the fallback crackle material. If you expect standalone VR playback, ship a pre-baked normal map or lower `displacement_strength`.

## Extending The Demo
- Swap `queer_colors` at runtime to build palettes driven by guest interactions or day/night cycles.
- Feed a gamepad/XR slider into `melt_strength` for live sculpting performances.
- Duplicate the dictionary pattern for other baroque elements (arches, cornices) to build a full pavilion of melting architecture.

## References & Inspiration
- Gian Lorenzo Bernini, **Baldacchino** (1623–1634) — twisting Solomonic columns at St. Peter's Basilica.
- Kate Crawford & Vladan Joler, **Anatomy of an AI System** — data colonialism mapped as baroque machinery.
- Legacy queer club scenography; neon-fueled stage lighting to accent curvature and drips.
