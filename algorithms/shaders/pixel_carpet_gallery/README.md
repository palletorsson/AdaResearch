# Pixel Carpet Gallery

A corridor completely covered in bold pixel-art carpets — floor, walls, and ceiling. Inspired by Art to Eat textile installations: each panel uses a different procedural domain pattern, wallpaper group, and neon palette, all rendered via `wallpaper_tile.gdshader` on the GPU.

## Layout

A straight corridor (default 30m long × 6m wide × 4m tall) tiled on every surface:

- **Floor** — large carpet panels spanning the corridor width.
- **Walls** — vertical panels lining both sides.
- **Ceiling** — overhead panels completing the immersion.

Each panel gets a unique seed, wallpaper group, and palette assignment.

## Palettes

Ten curated palettes (Electric Pop, Hot Sunset, Cool Digital, Neon Forest, Candy Stripe, Brutalist, Vaporwave, Bauhaus, Pixel Acid, Pastel Glitch), each defined as five colors.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `corridor_length` | 30.0 | Length in meters |
| `corridor_width` | 6.0 | Width in meters |
| `corridor_height` | 4.0 | Height in meters |

## Files

- `pixel_carpet_gallery.gd` — Corridor shell, floor/wall/ceiling tiling, lighting.
- `pixel_carpet_gallery.tscn` — Main scene.
