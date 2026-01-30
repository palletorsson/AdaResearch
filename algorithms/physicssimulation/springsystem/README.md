# Spring-Mass System

Interactive network of masses connected by springs — watch physics unfold as forces propagate through the network.

## QFEP Connection

Spring systems embody **oscillation between order and chaos**. Springs want equilibrium (F, rest length) but perturbations propagate through the network, creating complex dynamics (E). Damping gradually reduces chaos; without it, the system would oscillate forever.

## How It Works

```
    ○ ○ ○ ○  ← Fixed anchors
    │\│/│\│
    ○─○─○─○
    │/│\│/│
    ○─○─○─○
    │\│/│\│
    ○─○─○─○  ← Free masses
```

Each spring applies Hooke's Law:
```
F = -k × (length - rest_length)
```

Each mass integrates forces:
```
acceleration = forces / mass
velocity += acceleration × dt
velocity *= damping
position += velocity × dt
```

## Parameters

### Springs
| Export | Default | Description |
|--------|---------|-------------|
| `spring_stiffness` | 50.0 | k value in Hooke's Law |
| `damping` | 0.95 | Energy loss per frame |
| `rest_length` | 2.0 | Natural spring length |
| `max_spring_length` | 8.0 | Break threshold |

### Masses
| Export | Default | Description |
|--------|---------|-------------|
| `mass_count` | 20 | Total mass points |
| `mass_value` | 1.0 | Mass in kg |
| `mass_radius` | 0.2 | Visual size |
| `anchor_count` | 4 | Fixed points |

### Forces
| Export | Default | Description |
|--------|---------|-------------|
| `gravity` | -9.8 | Downward acceleration |
| `enable_wind_force` | true | Add wind perturbation |
| `wind_strength` | 2.0 | Wind force magnitude |

### Interaction
| Export | Default | Description |
|--------|---------|-------------|
| `enable_mouse_interaction` | true | Click to apply force |
| `mouse_force_strength` | 10.0 | Click force magnitude |
| `auto_interaction` | true | Automatic perturbations |

### Visualization
| Export | Default | Description |
|--------|---------|-------------|
| `show_springs` | true | Draw connecting lines |
| `color_by_tension` | true | Color springs by stretch |
| `show_velocity_vectors` | false | Display mass velocities |

## Color Palette

Uses vibrant queer color palette:
- Hot pink, Purple, Cyan, Gold, Lime

Springs colored by tension: blue (compressed) → red (stretched).

## Files

| File | Purpose |
|------|---------|
| `spring_system.tscn` | Scene |
| `spring_system.gd` | Physics simulation |

## Usage

```gdscript
var springs = preload("res://algorithms/physicssimulation/springsystem/spring_system.tscn").instantiate()
springs.spring_stiffness = 100.0  # Stiffer springs
springs.damping = 0.9  # More damping
add_child(springs)
```

## Physics Notes

- **Stiff springs + low damping** = energetic bouncing
- **Soft springs + high damping** = jelly-like wobble
- **Zero damping** = perpetual motion (energy conserved)
- **High gravity + stiff springs** = fast oscillation

## VR Experience

Watch the spring network respond to gravity and wind. The tension coloring shows stress distribution — stretched springs turn red, compressed turn blue. Auto-interaction keeps the system lively; click to add your own perturbations.

## Applications

Spring-mass systems model:
- **Cloth simulation**: Grid of masses
- **Soft body physics**: Volume-preserving networks
- **Bridge stress**: Load distribution
- **Molecular dynamics**: Atomic bonds

## See Also

- `softbodies/` — Godot's SoftBody3D
- `joint/` — Physics joints and constraints
- `oscillation/` — Harmonic motion
