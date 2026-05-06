# Noise Terrain

Procedural terrain with multi-octave noise and queer color palette — walkable landscapes from mathematical randomness.

## QFEP Connection

Terrain is **ordered randomness**. Noise provides the chaos (E); octave layering and height scaling impose structure (F). The `bulginess` parameter literally controls how much the landscape bulges beyond its bounds. Queer aesthetics: terrain that refuses neutral earth tones.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `terrain_size` | 100 | World units |
| `terrain_resolution` | 200 | Mesh density |
| `noise_scale` | 1.0 | Feature frequency |
| `height_multiplier` | 5.0 | Vertical exaggeration |
| `bulginess` | 1.0 | Bulge amount |
| `octaves` | 4 | Noise layers |
| `color_shift` | 0.5 | Palette hue offset |

## Features

- Multi-octave noise layering
- Secondary noise for detail
- Bulge noise for organic variation
- Contour lines (topographic)
- Heightmap shader with queer colors

## Files

| File | Purpose |
|------|---------|
| `noise_terrain.gd` | Terrain generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var terrain = QueerNoiseTerrain.new()
terrain.height_multiplier = 10.0
terrain.color_shift = 0.8  # Purple-pink palette
add_child(terrain)
```

## See Also

- `noiselayers/` — More sophisticated layering
- `pheromone_terrain/` — Agent-modified terrain
