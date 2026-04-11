# Grid Editor — Desktop Glass Rack Layout Designer

Desktop GUI for designing glass rack layouts on an XY grid. Generates configurations that the VR glass rack system renders.

## Structure

| Directory | Contents |
|-----------|----------|
| `scripts/` | GDScript runtime — editor, mesh factory, canvas, capture, subset loader |
| `scenes/` | Godot scene files for the editor UI |
| `layouts/` | Saved layout JSON files |
| `subsets/` | Element subset definitions |

See also `ARCHITECTURE.md` and `PLAN.md` in this directory.

## Scripts

| File | Role |
|------|------|
| `scripts/editor_main.gd` | Main editor control — grid canvas, camera orbit, element palette |
| `scripts/glass_mesh_factory.gd` | Generates glass pipe meshes from element definitions |
| `scripts/grid_canvas.gd` | 2D grid interaction and element placement |
| `scripts/grid_editor_capture.gd` | Screenshot capture for grid layouts |
| `scripts/primitive_scene_builder.gd` | Builds preview scenes from primitives |
| `scripts/subset_loader.gd` | Loads element subset definitions |

Web alternative: `localhost:3003/grid-editor`
