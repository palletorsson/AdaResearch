# Cave Random Walk

A 3D cave generator that uses multiple biased random walkers to carve interconnected tunnel networks through a solid voxel grid. This artifact teaches the **drunkard's walk** (random walk) approach to procedural cave generation -- how stochastic agents moving through space can create organic, navigable cave systems with guaranteed connectivity.

## How It Works

The algorithm operates in three phases using multiple walker agents:

1. **Phase A -- Inward convergence**: Walkers start at the four sides of the grid at ground level (y=0). Each walker takes biased random steps toward the center, carving 2-voxel-tall, 1-voxel-radius tunnels at each step. The bias is 70% toward the center, ensuring all walkers eventually meet.
2. **Phase B -- Center exploration**: Once walkers reach the center, they jump to y=1 and take 10 random lateral steps, creating a connected hub room.
3. **Phase C -- Vertical climb**: Walkers ascend from y=2 to y=9, taking `steps_per_level` lateral steps at each elevation. Movement mixes center-biased steps (75% chance) with pure random steps (25%), creating winding vertical passages.

Finally, a guaranteed spawn pocket is carved near the grid center at y=1.

Each carve operation uses `_carve_ball()`, which clears a cylindrical region with configurable radius and headroom (2 voxels tall for player clearance). The result is rendered as individual `MeshInstance3D` boxes with optional `StaticBody3D` collision.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size` | Vector3i | (10,10,10) | Dimensions of the voxel grid |
| `cube_size` | float | 1.0 | World-space size of each voxel |
| `walkers` | int | 4 | Number of random walker agents |
| `steps_per_level` | int | 8 | Lateral steps taken per vertical level during Phase C |
| `seed` | int | 1337 | Random seed for reproducibility |
| `show_gizmos` | bool | false | Show a sphere marker at the spawn point |
| `make_collision` | bool | true | Generate StaticBody3D collision for each solid voxel |

## Features

- **Biased random walk** -- walkers are attracted toward the center, guaranteeing all tunnels connect
- **Three-phase carving** -- inward convergence, hub exploration, and vertical climbing create varied cave geometry
- **Guaranteed connectivity** -- all walkers converge at the center, and a spawn pocket ensures a safe starting area
- **Headroom enforcement** -- every carve clears 2 voxels vertically, ensuring walkable tunnel height
- **Collision generation** -- optional StaticBody3D/BoxShape3D per voxel for physics interaction
- **UI panel** (CaveUI.gd) -- sliders for grid width, height, walkers, steps per level; seed spinbox with regenerate/randomize buttons

## Files

- `caverandomwalk.gd` -- Core random walk carving algorithm (CaveGenerator class), grid management, mesh building, collision generation
- `CaveUI.gd` -- Control panel UI for adjusting cave parameters and triggering regeneration
- `caverandomwalk.tscn` -- Scene file
