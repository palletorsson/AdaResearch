# Color Lines

Dynamic flowing colored lines weaving through 3D space — mesmerizing VR visual experience.

## QFEP Connection

Lines are **paths through color space**. Start and end colors define a gradient (F, endpoints); flow animation creates continuous transformation (E, movement). The shader interpolates — λ as the journey between colors.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `line_count` | 25 | Number of lines |
| `points_per_line` | 100 | Curve resolution |
| `animation_speed` | 1.0 | Path animation |
| `line_length` | 15.0 | Line extent |
| `flow_speed` | 2.0 | Color flow rate |

## Shader Features

- Gradient from `color_start` to `color_end`
- `glow_intensity` for emission
- `thickness_variation` along line
- `pulse_frequency` for breathing effect

## Files

| File | Purpose |
|------|---------|
| `colorlines.gd` | Line generator |
| `*.tscn` | Scene |

## Usage

```gdscript
var lines = preload("res://algorithms/color/colorlines/colorlines.tscn").instantiate()
lines.line_count = 50
add_child(lines)
```

## See Also

- `colortrails/` — Hand-tracked color trails
- `wavefunctions/hallway_lines/` — Architectural lines
