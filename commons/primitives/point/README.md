# Point Primitives

Point primitives provide multiple point variants for different teaching and performance needs in VR.

## Main Scenes

- `point.tscn`: generic pickable point with coordinate label.
- `interactive_point_origin.tscn`: pickable point that draws a live line to origin while held.
- `static_point.tscn`: non-pickable reference point.
- `grab_sphere_point*.tscn`: legacy/variant pickable spheres with color/text presets.
- `grab_sphere_point_snap.tscn`: snapped-grid grab point variant for discrete placement.
- `draw_dot.tscn`: grabbable trace tool that records motion as a persistent line.
- `draw_dot_time_domain.tscn`: `draw_dot` variant for time-domain use cases.
- `player_trace.tscn`: passive locomotion trace recorder for whole-map movement history.

## `interactive_point_origin` Behavior

`interactive_point_origin.gd` extends `XRToolsPickable` and adds:

- glow material on pickup
- pickup/drop haptic pulses
- pickup tone via generated `AudioStreamWAV`
- live coordinate label (format cycles per pickup)
- line to `origin_point` while held

The line mesh is created once and reused. This avoids per-frame mesh allocation in VR.

## `static_point` Behavior

`static_point.gd` creates a simple emissive sphere and optional coordinate label.
It is added to `no_gravity_gun` group so it stays as a stable visual reference.

## `draw_dot` Behavior

`draw_dot.gd` builds a trail from controller motion using an `ImmediateMesh`.

- records points only when grabbed (`record_only_when_grabbed`)
- enforces minimum segment distance to limit oversampling
- caps points via `trail_max_points`
- supports tag-trigger unlock flows through `trigger_tag` and `trigger_action`
- can optionally show a local reference frame and data table

## `player_trace` Behavior

`player_trace.gd` records the XR origin path over time and renders it as a line strip.

- records while the player moves, no grab action required
- caps memory with `trail_max_points`
- supports optional time-based fading
- uses `trace_height_offset` to avoid z-fighting with floor surfaces

## VR Notes

- Keep update-heavy logic conditional on active interaction (`_is_held`).
- Prefer low-poly spheres for tiny markers.
- Use static points when interaction is not required.
- For trace tools, tune `trail_max_points` and `min_segment_distance` before adding many instances in one map.

## Registry Keys Used in Maps

Common keys from `grid_artifacts.json`:

- `point`
- `static_point`
- `interactive_point_origin`
- `grab_sphere_point`
- `grab_sphere_point_snap`
- `grab_sphere_point_with_text`
- `grab_sphere_point_with_color`
- `draw_dot`
- `draw_dot_time_domain`
