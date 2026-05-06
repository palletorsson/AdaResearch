# Mondrian Grid

Procedural art generator in the style of Piet Mondrian — recursive grid subdivision with primary colors and black lines.

## QFEP Connection

Mondrian sought **universal harmony through pure abstraction** — reducing art to primary colors and orthogonal lines. The algorithm mirrors this: random recursive subdivision (E) constrained by strict geometric rules (F). The result is unique each time yet unmistakably Mondrian.

## How It Works

```
┌────────────────────────┐
│          │             │
│   ■■■    │             │
│   ■■■    │─────────────│
│──────────│      ■      │
│          │      ■      │
│          │─────────────│
│          │  ■■■■■■■■   │
└────────────────────────┘

■ = Colored section (red, blue, yellow)
  = White section
─│ = Black grid lines
```

Algorithm:
1. Start with full rectangle
2. Randomly decide to split (vertical or horizontal)
3. Recurse on both halves
4. Stop when sections are small enough
5. Randomly assign colors or white to leaf sections

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `grid_width` | 20 | Total width in units |
| `grid_depth` | 20 | Total depth in units |
| `min_block_size` | 2 | Minimum section size |
| `line_thickness` | 0.2 | Black line width |
| `block_height` | 1.0 | Extrusion height |
| `split_probability` | 0.75 | Chance to subdivide |
| `colored_section_probability` | 0.3 | Chance of color vs white |
| `random_seed` | 42 | Deterministic generation |

## 3D Implementation

Unlike 2D Mondrian, this generates a 3D platform:
- **White sections**: Solid blocks (walkable)
- **Colored sections**: Holes (empty space)
- **Black lines**: Extruded edges between sections

## Components

| File | Purpose |
|------|---------|
| `mondrian_generator_3d.gd` | Main BSP subdivision |
| `mondrian_ghost_block.gd` | Animated fading blocks |
| `mondrian_spawner.gd` | Mondrian-styled projectile spawner |
| `mondrian_run.tscn` | Playable run/game scene |
| `mondrian_spawner.tscn` | Spawner prefab |

## Ghost Blocks

Some blocks pulse between visible and transparent:
```gdscript
var alpha = (sin(t * 1.5) * 0.5 + 0.5) * 0.7 + 0.1
```

Creates an eerie, unstable floor.

## Spawners

Mondrian-styled cube spawners:
- Black frame with colored core
- Random Mondrian color (red, blue, yellow)
- Emissive glow
- Projects cubes across the grid

## Usage

```gdscript
var mondrian = preload("res://algorithms/arrays/mondrian_grid/mondrian_run.tscn").instantiate()
mondrian.random_seed = 0  # Random each time
mondrian.colored_section_probability = 0.4  # More holes
add_child(mondrian)
```

## VR Experience

Walk across the Mondrian grid. White sections are solid; colored sections are holes (don't fall in). Ghost blocks fade in and out — you can never quite trust the floor. Spawners add projectile hazards in Mondrian's primary colors.

## Art Historical Context

Piet Mondrian (1872-1944) developed neoplasticism:
- **Only** primary colors (red, yellow, blue) + white + black
- **Only** horizontal and vertical lines
- **Asymmetric balance**: Dynamic equilibrium

His grids represent the underlying order of the universe — pure relationships free from representation.

## See Also

- `patterngeneration/truchettiles/` — Other procedural patterns
- `proceduralgeneration/binary_space_partitioning/` — BSP algorithm
- `criticaltheory/` — Art-theory intersections
