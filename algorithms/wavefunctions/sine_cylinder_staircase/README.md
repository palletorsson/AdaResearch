# Sine Cylinder Staircase

Spiral staircase with optional wave modulation — walkable helical architecture.

## QFEP Connection

Stairs are **discrete steps approximating continuous rise**. The spiral wraps linear ascent around a cylinder (F, geometry); wave amplitude adds organic variation (E, deviation). `WAVE_AMPLITUDE = 0` is pure helix; higher values introduce undulation. λ as architectural rhythm.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `STEP_COUNT` | 80 | Number of steps |
| `TOTAL_TURNS` | 2.0 | Full rotations |
| `BASE_RADIUS` | 1.6 | Helix radius |
| `WALKWAY_OFFSET` | 0.9 | Step offset from center |
| `STEP_RISE` | 0.10 | Height per step |
| `STEP_THICKNESS` | 0.22 | Step depth |
| `STEP_WIDTH` | 2.0 | Step width |
| `WAVE_AMPLITUDE` | 0.0 | Undulation amount |
| `WAVE_FREQUENCY` | 2.0 | Undulation rate |

## Files

| File | Purpose |
|------|---------|
| `sine_cylinder_staircase.gd` | Generator |
| `*.tscn` | Scene |

## Usage

```gdscript
var stairs = preload("res://algorithms/wavefunctions/sine_cylinder_staircase/staircase.tscn").instantiate()
stairs.WAVE_AMPLITUDE = 0.3  # Wavy path
add_child(stairs)
```

## See Also

- `transformation/carousel_cake/` — Nested rotation
- `arrays/` — Repetitive structures
