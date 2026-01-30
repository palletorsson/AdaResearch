# Carousel Cake

Multi-layer rotating structure with candy-colored aesthetics — nested cylinders spinning at different rates.

## QFEP Connection

A carousel demonstrates **nested rotation** — each layer moves independently yet the whole coheres. The `rotation_speed_multiplier` creates hierarchy: inner layers spin faster, outer slower (or vice versa). This is λ as visual rhythm — order (constant ratios) producing dynamic complexity.

## How It Works

```
Top view (rotating):         Side view:
    ╭─────────╮                 ═══ Layer 7
   ╱  ╭───╮    ╲               ═════ Layer 6
  │  ╱ ╭─╮ ╲    │             ═══════ Layer 5
  │ │ │ ○ │ │   │            ╱║║║║║║║╲ Layer 4 (tall center)
  │  ╲ ╰─╯ ╱    │             ═══════ Layer 3
   ╲  ╰───╯    ╱               ═════ Layer 2
    ╰─────────╯                 ═══ Layer 1
    
Each ring rotates at different speed.
```

## Parameters

### Structure
| Export | Default | Description |
|--------|---------|-------------|
| `layer_radii` | [4,3.5,3,1.6,3,3.5,4,5] | Radius per layer |
| `layer_heights` | [0.05,...,3.0,...] | Height per layer |
| `base_radial_segments` | 32 | Cylinder smoothness |
| `segments_increment` | 2 | More segments per layer |

### Animation
| Export | Default | Description |
|--------|---------|-------------|
| `base_rotation_speed` | 0.5 | Starting speed |
| `rotation_speed_multiplier` | 1.2 | Speed ratio between layers |

### Collision
| Export | Default | Description |
|--------|---------|-------------|
| `enable_colliders` | true | Physics collision |
| `collision_layer/mask` | 1 | Collision groups |

### Materials
| Export | Default | Description |
|--------|---------|-------------|
| `alternating_colors` | true | Alternate layer colors |
| `use_stripe_shader` | true | Animated stripes |
| `color_a` | Hot pink | Primary color |
| `color_b` | Cyan | Secondary color |
| `base_stripe_count` | 12.0 | Stripe frequency |
| `stripe_width` | 0.5 | Stripe size |
| `stripe_density_multiplier` | 1.3 | Stripes scale with rotation |

## Stripe Shader

Custom shader creates animated stripes synchronized with rotation:
```
stripe_density = base + (layer * multiplier)
```

Faster layers have denser stripes, creating visual continuity.

## Files

| File | Purpose |
|------|---------|
| `carousel_cake.gd` | Main controller |
| `carousel_stripes.gdshader` | Stripe animation shader |
| `*.tscn` | Scene file |

## Usage

```gdscript
var cake = preload("res://algorithms/transformation/carousel_cake/carousel_cake.tscn").instantiate()
cake.rotation_speed_multiplier = 1.5  # Faster ratio
cake.color_a = Color.RED
cake.color_b = Color.WHITE  # Candy cane style
add_child(cake)
```

## VR Experience

Stand beside the carousel cake. Watch the layers rotate at different speeds — some clockwise, some counter. The stripes create mesmerizing patterns. With collision enabled, you can touch and interact with the spinning surfaces.

## Applications

- **Kinetic sculpture**: Moving art installations
- **Visualizing ratios**: Gear relationships, planetary motion
- **VR environment**: Dynamic decorative element
- **Physics demo**: Angular velocity composition

## See Also

- `oscillation/` — Rotational motion
- `arrays/` — Repetitive structures
- `primitives/` — Basic shape generation
