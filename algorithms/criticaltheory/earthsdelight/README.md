# Earth's Delight

Procedural landscape generator inspired by Hieronymus Bosch — strange plants, surreal terrain, and triptych color palettes.

## QFEP Connection

Bosch painted **the boundary between order and chaos**. His Garden triptych shows Paradise (F), Earthly Pleasures (λ), and Hell (E) as continuous space. This generator uses mutation factors and color palettes to position landscapes on that spectrum. High `mutation_factor` = more hellish; low = more paradisiacal.

## Triptych Structure

```
┌─────────────┬─────────────┬─────────────┐
│   PARADISE  │   PLEASURE  │    HELL     │
│             │             │             │
│ Light green │ Pink/blue   │ Red/black   │
│ Ordered     │ Abundant    │ Chaotic     │
│ Pristine    │ Excessive   │ Corrupted   │
└─────────────┴─────────────┴─────────────┘
     F             λ              E
```

## Color Palettes

### Paradise
- Light green, light blue, cream
- Soft, pastoral, innocent

### Pleasure
- Pink, yellow-green, blue, peach, magenta
- Saturated, fleshy, abundant

### Hell
- Red, dark blue, black, gold, purple
- Harsh, metallic, burning

## Parameters

### Landscape
| Export | Default | Description |
|--------|---------|-------------|
| `landscape_size` | (50, 50) | Terrain dimensions |
| `height_scale` | 5.0 | Terrain height variation |
| `terrain_octaves` | 4 | Noise complexity |
| `terrain_seed` | 0 | Random seed |
| `terrain_frequency` | 0.8 | Feature scale |

### Plants
| Export | Default | Description |
|--------|---------|-------------|
| `plant_count` | 200 | Number of plants |
| `strange_plant_types` | 10 | Variation types |
| `mutation_factor` | 0.7 | How bizarre (0-1) |
| `plant_scale_min` | 0.5 | Smallest plants |
| `plant_scale_max` | 5.0 | Largest plants |

## Plant Generation

Plants are procedurally assembled from:
- **Stems**: Various curved/twisted shapes
- **Bulbs**: Spherical, egg-like forms
- **Leaves**: Flat, curling extensions

High mutation factor creates:
- Impossible geometries
- Fused forms
- Inverted proportions

## Files

| File | Purpose |
|------|---------|
| `earths_delight.gd` | Landscape generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var garden = preload("res://algorithms/criticaltheory/earthsdelight/earths_delight.tscn").instantiate()
garden.mutation_factor = 0.3  # More paradisiacal
garden.plant_count = 400  # Dense vegetation
add_child(garden)
```

## VR Experience

Walk through a landscape that feels familiar yet wrong. The plants are almost recognizable — but their proportions are off, their colors too vivid. Is this paradise or nightmare? The mutation factor determines where you land on that continuum.

## About Bosch

Hieronymus Bosch (c. 1450-1516) painted surreal, fantastical scenes centuries before surrealism existed. His Garden of Earthly Delights triptych remains one of art history's most analyzed and mysterious works — a meditation on pleasure, sin, and the strangeness of existence.

## See Also

- `pipilottiristworld/` — Contemporary surrealism
- `lsystems/` — Plant generation
- `emergentsystems/ecosystemsimulation2/` — Living landscapes
