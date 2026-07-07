# prism/

A configurable triangular-prism primitive — Godot's built-in `PrismMesh` wrapped as a project primitive with the project's grid-shader aesthetic and `apply_grid_config()` support.

## Files

| File | What |
|------|------|
| `prism.gd` | Configurable script — exports `left_to_right`, `size`, `fill_color`, `wireframe_color`. Has `@identity` + `class_name Prism` + `apply_grid_config()`. |
| `prism.tscn` | Thin scene wrapping `prism.gd`. UID is `uid://7cmeoec6zza1u`. |
| `walkableprism.tscn` | Larger walk-on variant. |

## Not the same as the other prisms

The project has three "prism" folders that mean different things:

| Folder | Shape | Notes |
|--------|-------|-------|
| `prism/` | symmetric or skewed **triangular prism** | Godot `PrismMesh`. Top-edge slides via `left_to_right`. |
| `prismblock/` | asymmetric **5-face ridged wedge** | Procedural — 4-vertex base + 2-vertex ridge offset off-centre. Different shape entirely. |
| `prisms/` | knowledge_prism — a **multi-faceted display object** | Different concept. Not a geometric primitive. |

If you want a roof / awning / ramp piece, you usually want `prismblock` (asymmetric ridge gives the roof its directional read). If you want a wedge that can be slid into symmetric or right-triangular form, you want `prism`.

## Usage

```gd
# Inline
var p := Prism.new()
p.left_to_right = -1.0   # right-triangle prism (top edge fully left)
p.size = Vector3(2.0, 1.0, 1.0)
add_child(p)

# Via grid system
# In map_data.json, on the interactables layer:
#   "prism#config:left_to_right=0.5:size=2,1,1"
```
