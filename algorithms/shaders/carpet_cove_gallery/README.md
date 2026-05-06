# Carpet Cove Gallery

A walkable gallery of pattern cove displays, each showing a different wallpaper-group pattern on a curved concave surface. The cove form means the pattern flows from the floor surface up through a smooth curve onto the vertical back — like a photo backdrop.

## Layout

Grid-aligned corridor with two facing rows of coves separated by a walkable aisle:

```
[cove][cove][cove]     ← back row (wall-mounted, facing player)
[    walk space   ]    ← aisle
[cove][cove][cove]     ← front row (facing back wall)
```

Each cove occupies a configurable number of grid cells (default 3×2m). All rendering uses the shared `wallpaper_tile.gdshader` with procedurally assigned palettes and wallpaper group parameters.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `corridor_cells_x` | 12 | Corridor width in grid cells |
| `corridor_cells_z` | 30 | Corridor length in grid cells |
| `cove_width_cells` | 3 | Width of each cove display |
| `cove_depth_cells` | 2 | Depth of each cove (floor + curve) |
| `aisle_cells` | 3 | Walkway width between rows |

## Palettes

Ten curated neon/textile palettes (Electric Pop, Hot Sunset, Cool Digital, Neon Forest, Candy Stripe, Brutalist, Vaporwave, Bauhaus, Italian Textile, Synthwave), each defined as five colors: background, primary, secondary, accent1, accent2.

## Files

- `carpet_cove_gallery.gd` — Gallery layout, cove instantiation, floor, and lighting.
- `carpet_cove_gallery.tscn` — Main scene.
- `cove_display.gd` — Individual cove display with curved surface geometry.
- `cove_display.tscn` — Cove display scene.
