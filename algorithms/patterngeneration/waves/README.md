# Waves (Water Surface)

Procedural water shader with flow maps, refraction, and underwater fog — realistic fluid surface simulation.

## QFEP Connection

Water surfaces embody **continuous transformation**. Waves propagate (F, predictable physics), but their interference creates ever-changing patterns (E, visual complexity). The `flow_map` directs this transformation — channeling chaos into controlled currents. λ as fluid dynamics.

## How It Works

```
Surface:                    Underwater:
╭~~~~~~~~~~~~~~~~~~~~~╮     ╭─────────────────────╮
  ~~~~  ~~~~  ~~~~           │ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ │
    ~~~~  ~~~~              │ ▒▒ fog gradient ▒▒ │
  ~~~~  ~~~~  ~~~~           │ ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ │
╰~~~~~~~~~~~~~~~~~~~~~╯     ╰─────────────────────╯

Wave displacement + Flow direction + Refraction + Depth fog
```

## Parameters

### Water Properties
| Export | Default | Description |
|--------|---------|-------------|
| `water_color` | Blue-gray | Surface tint |
| `metallic` | 0.0 | Reflection type |
| `roughness` | 0.5 | Surface smoothness |

### Flow Settings
| Export | Default | Description |
|--------|---------|-------------|
| `flow_strength` | 1.0 | Current intensity |
| `flow_speed` | 1.0 | Animation rate |
| `tiling` | 1.0 | Texture repetition |

### Underwater Fog
| Export | Default | Description |
|--------|---------|-------------|
| `water_fog_color` | Blue | Underwater tint |
| `water_fog_density` | 0.15 | Visibility falloff |

### Refraction
| Export | Default | Description |
|--------|---------|-------------|
| `refraction_strength` | 0.25 | Light bending amount |

### Transparency
| Export | Default | Description |
|--------|---------|-------------|
| `transparency_` | 0.8 | Surface opacity |
| `depth_fade_distance` | 2.0 | Edge fade distance |

## Textures

| Texture | Purpose |
|---------|---------|
| `flow_map` | Direction of water flow (RG = XY direction) |
| `noise_texture` | Surface displacement noise |
| `derivative_height_texture` | Normal calculation input |

## Files

| File | Purpose |
|------|---------|
| `waves.gd` / `water_surface.gd` | Material setup |
| `catwater.gdshader` | Water shader |
| `*.tscn` | Demo scene |

## Usage

```gdscript
var water = WaterSurface.new()
water.mesh = PlaneMesh.new()
water.water_color = Color(0.2, 0.5, 0.7, 0.9)
water.flow_speed = 2.0
add_child(water)
```

## Shader Features

- **Flow map animation**: Water follows painted directions
- **Dual-layer waves**: Two noise layers at different speeds
- **Screen-space refraction**: Objects below surface distort
- **Depth-based transparency**: Shallow = clearer
- **Underwater fog**: Gradual color absorption

## VR Experience

Stand beside (or in) the water surface. Watch waves propagate according to the flow map. Look through the surface to see refraction distorting the view below. The water feels liquid — light bends, fog obscures depth, and the surface never repeats exactly.

## Flow Map Painting

Flow maps are textures where:
- **Red channel**: X-direction flow
- **Green channel**: Y-direction flow
- **0.5 = no flow**: Values above/below indicate direction

Paint in an image editor to create rivers, whirlpools, or currents.

## See Also

- `wavefunctions/` — Wave mathematics
- `shaders/` — Other shader effects
- `randomness/noise/` — Procedural noise
