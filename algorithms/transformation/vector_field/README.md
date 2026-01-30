# Vector Field

Interactive 3D vector field visualization with particles tracing flow lines — see the invisible forces that shape motion.

## QFEP Connection

Vector fields are **the mathematics of change** — at every point in space, a direction and magnitude. They describe electromagnetic fields, fluid flow, gravitational pull. This visualization makes the invisible visible: order (F) emerges from the field equations, while noise and turbulence add chaos (E).

## Field Types

| Type | Description | Pattern |
|------|-------------|---------|
| **Vortex** | Rotation around center | Circular flow |
| **Saddle** | Converge on one axis, diverge on another | X-shaped |
| **Source** | Emanate outward from center | Explosion |
| **Sink** | Flow inward to center | Implosion |
| **Tornado** | Vortex with vertical component | Spiral upward |
| **Wave** | Sinusoidal oscillation | Ripples |
| **Circular** | Constant circular motion | Orbital |

## How It Works

```
┌────────────────────────────────────┐
│      Vector Grid (15³ = 3375)      │
│   ↗ → ↘   ↗ → ↘   ↗ → ↘          │
│   ↑   ↓   ↑   ↓   ↑   ↓          │
│   ↖ ← ↙   ↖ ← ↙   ↖ ← ↙          │
│                                    │
│   Particles follow field vectors   │
│   with RK4 integration for accuracy│
└────────────────────────────────────┘
```

1. **Field computation**: Vector at each grid point based on field type
2. **Noise modulation**: Perlin noise adds turbulence
3. **Particle advection**: Particles follow vectors (RK4 integration)
4. **Trail rendering**: History of particle positions

## Parameters

### Field
| Export | Default | Description |
|--------|---------|-------------|
| `grid_size_x/y/z` | 15 | Vector grid dimensions |
| `spacing` | 1.0 | Distance between vectors |
| `field_type` | Vortex | Which field equation |
| `field_strength` | 1.0 | Vector magnitude multiplier |
| `rotation_speed` | 0.5 | Time evolution speed |

### Noise
| Export | Default | Description |
|--------|---------|-------------|
| `noise_enabled` | true | Add turbulence |
| `noise_strength` | 0.5 | Turbulence intensity |
| `noise_scale` | 0.3 | Turbulence frequency |
| `turbulence_octaves` | 3 | Noise detail layers |

### Particles
| Export | Default | Description |
|--------|---------|-------------|
| `particle_count` | 500 | Number of tracers |
| `particle_speed` | 2.0 | Movement speed |
| `use_rk4_integration` | true | Accurate integration (vs Euler) |
| `trail_enabled` | true | Show particle history |
| `trail_length` | 50 | Trail point count |

## Tool Mode

Marked `@tool` — adjust parameters in the editor and see instant updates. Great for exploring different field configurations.

## Files

| File | Purpose |
|------|---------|
| `vector_field.tscn` | Scene root |
| `vector_field.gd` | Field computation, particle simulation |

## Usage

```gdscript
var field = preload("res://algorithms/transformation/vector_field/vector_field.tscn").instantiate()
field.field_type = 4  # Tornado
field.noise_strength = 0.8  # More turbulence
field.particle_count = 1000
add_child(field)
```

## RK4 Integration

Uses fourth-order Runge-Kutta for particle advection — more accurate than simple Euler integration, especially important for curved trajectories like vortices.

## VR Experience

Stand inside the vector field and watch particles flow around you. The arrows show the field direction, the particles show how objects would move. Switch between field types to feel the difference between a calm source flow and a chaotic tornado.

## Mathematical Note

Each field type corresponds to different differential equations:
- **Source/Sink**: ∇·F ≠ 0 (divergence)
- **Vortex**: ∇×F ≠ 0 (curl)
- **Saddle**: Hyperbolic fixed point

## See Also

- `forces/` — Physics-based particle motion
- `steering/` — Agent-based flow following
- `chaos/` — Strange attractors as vector fields
