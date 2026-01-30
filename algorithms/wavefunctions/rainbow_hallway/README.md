# Rainbow Hallway

CSG corridor with animated rainbow gradient shader — walkable chromatic experience.

## QFEP Connection

The rainbow is **order in color space**. Hue progresses through the spectrum (F, sequence); animation shifts the gradient over time (E, change). Walking through is moving through wavelength — λ as literal light frequency.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `animation_speed` | 1.0 | Gradient shift rate |
| `gradient_offset` | 0.5 | Color starting point |
| `glow_intensity` | 0.5 | Emission brightness |
| `emission_strength` | 0.3 | Glow amount |

## Files

| File | Purpose |
|------|---------|
| `rainbow_hallway.gd` | Main controller |
| `rainbow_hallway.gdshader` | Gradient shader |
| `*.tscn` | Scene |

## Usage

```gdscript
var hallway = preload("res://algorithms/wavefunctions/rainbow_hallway/rainbow.tscn").instantiate()
hallway.animation_speed = 2.0
add_child(hallway)
```

## See Also

- `primitives/rainbow/` — Rainbow arcs
- `color/` — Color theory
