# Interactive Point Primitive

A pickable 3D point helper that displays its world coordinates with a floating label. Ideal for geometry demos, level markup, or debugging transforms in VR.

## Scene Assets
- `point.tscn` - base point prefab with grab sphere and floating label wiring.
- `point.gd` - controller script that spawns/updates the label, mirrors grabs, and offers utility methods for external scripts.
- `point_tutorial.gd` - in-world BBCode tutorial snippet.
- `code_prompt.txt` - instructions for regenerating `point.gd` via an AI assistant.
- `meta.json` - catalog metadata for menus and search tools.

## How It Works
1. `_ready()` calls `setup_point_scene()` to cache child nodes and spawn a `Label3D` displaying the grab sphere position.
2. `get_position_text()` samples `grab_sphere.global_position` (fallbacks to the node’s own transform) and formats it to one decimal place.
3. `_process()` refreshes the label text every frame so dragged points always show their current coordinates.
4. Helper methods (`set_point_position`, `set_point_color`, `set_label_*`) expose runtime tweaking without requiring external nodes to traverse the scene tree.

## Public API Highlights
- `set_point_position(Vector3)` - moves the point and updates the label.
- `set_point_color(Color)` - routes through `PointColor` helper if present; otherwise builds a simple emissive material.
- `get_pickable_sphere()` - returns the underlying grab sphere node for XR bindings.
- `is_grabbed()` - checks whether the point is currently picked up (if the grab module supports it).
- `set_label_visible(bool)` / `set_label_offset(Vector3)` / `set_label_color(Color)` - UI convenience helpers.

## Usage Tips
- Parent multiple `point.tscn` instances under a manager scene to tag anchors or manipulate geometry constraints.
- Add `PointColor` as a child to enable palette swapping across collections.
- Pair with line or vector primitives to visualize measurements and trajectories.

## Extending
- Replace the dynamic `Label3D` with a custom billboard mesh for stylized displays.
- Pipe the coordinate string into HUD widgets or logs for debugging sessions.
- Combine with `point_collection.tscn` to generate structured point sets from data files.
