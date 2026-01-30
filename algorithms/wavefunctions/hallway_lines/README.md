# Hallway Lines

Wall-to-wall sine wave tubes spanning a corridor — mesmerizing VR environment.

## QFEP Connection

Lines span the hallway like **frozen waves**. Sine functions define their paths (F, mathematical); amplitude and twist create visual complexity (E, variation). Walking through is walking through a waveform made architectural.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `points_per_line` | 120 | Curve resolution |
| `animation_speed` | 0.0 | Wave motion (0 = static) |
| `flow_speed` | 1.0 | Color animation |
| `hallway_width/length/height` | 12/60/8 | Corridor dimensions |
| `row_spacing` | 6.0 | Distance between lines |
| `span_wave_amp` | 2.2 | Vertical wave amount |
| `span_twist_amp` | 1.1 | Rotational wave |
| `span_frequency` | 1.5 | Wave frequency |
| `line_radius` | 0.3 | Tube thickness |

## Files

| File | Purpose |
|------|---------|
| `hallway_lines.gd` | Line generator |
| `*.tscn` | Scene |

## Usage

```gdscript
var lines = preload("res://algorithms/wavefunctions/hallway_lines/hallway.tscn").instantiate()
lines.span_wave_amp = 3.0  # More dramatic
add_child(lines)
```

## See Also

- `oscillation/` — Wave mathematics
- `arrays/` — Repeated elements
