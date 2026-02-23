# Point Primitives

Point primitives provide multiple point variants for different teaching and performance needs in VR.

## Main Scenes

- `point.tscn`: generic pickable point with coordinate label.
- `interactive_point_origin.tscn`: pickable point that draws a live line to origin while held.
- `static_point.tscn`: non-pickable reference point.
- `grab_sphere_point*.tscn`: legacy/variant pickable spheres with color/text presets.

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

## VR Notes

- Keep update-heavy logic conditional on active interaction (`_is_held`).
- Prefer low-poly spheres for tiny markers.
- Use static points when interaction is not required.

## Registry Keys Used in Maps

Common keys from `grid_artifacts.json`:

- `point`
- `static_point`
- `interactive_point_origin`
- `grab_sphere_point`
- `grab_sphere_point_with_text`
- `grab_sphere_point_with_color`
