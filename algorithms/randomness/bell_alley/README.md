# Bell Curve Alley

A corridor of cubes that widens according to a Gaussian distribution — narrow at the center, expanding at the edges.

## QFEP Connection

The bell curve (normal distribution) is nature's most common probability distribution. This alley visualizes **λ as spatial width**: the center is constrained (high F, low entropy), while the edges explode into possibility (high E). Walking through is walking from order to chaos and back.

## How It Works

```
        Z-axis (depth)
        ↓
    ════════════════════
    ██████████████████████  ← Wide (edge)
      ████████████████      
        ████████████        
          ████████          
            ████            ← Narrow (center)
          ████████          
        ████████████        
      ████████████████      
    ██████████████████████  ← Wide (edge)
    ════════════════════
```

The width at each Z-row follows the Gaussian function:

```
width_factor = exp(-z² / 2σ²)
row_width = lerp(1, max_width, 1 - width_factor)
```

Where `σ` (spread) controls how quickly the alley widens.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `grid_x` | 30 | Maximum width in cubes |
| `grid_z` | 60 | Depth (length) in cubes |
| `cube_spacing` | 1.0 | Distance between cube centers |
| `spread` | 4.0 | σ parameter — higher = wider center path |
| `height_y` | 0.0 | Vertical position of cubes |

## Randomness Element

20% of edge cubes are randomly skipped (`randf() > 0.8`), adding organic irregularity to the mathematically precise bell curve shape.

## Files

| File | Purpose |
|------|---------|
| `bell_alley.tscn` | Scene root |
| `BellAlley.gd` | Generation logic |

## Usage

```gdscript
var alley = preload("res://algorithms/randomness/bell_alley/bell_alley.tscn").instantiate()
alley.spread = 6.0  # Wider center path
alley.grid_z = 100  # Longer corridor
add_child(alley)
```

## VR Experience

Walk through the alley from one end to the other. Notice how the walls close in at the center (the peak of the bell curve) and open up at the edges (the tails). The random gaps break the mathematical perfection, making it feel more natural.

## See Also

- `random_bell_curve/` — Bell curve as terrain height
- `distributions/gaussian/` — Other Gaussian visualizations
