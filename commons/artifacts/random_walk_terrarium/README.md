# Random Walk Terrarium

A glass terrarium containing multiple random walkers that leave colored trails, demonstrating stochastic motion and diffusion scaling laws. Teaches the concept of random walks as memoryless, maximum-entropy processes.

## How It Works

Multiple walkers take discrete steps in uniformly random directions inside a bounded glass box. Three walk modes are available: 2D uniform (steps on the XZ plane), 3D uniform (steps on the unit sphere), and Levy flight (power-law distributed step sizes producing occasional large jumps). Boundary reflection keeps walkers contained. Mean squared displacement (MSD) is computed each frame and displayed, allowing learners to observe how MSD grows linearly with step count for standard walks and superlinearly for Levy flights.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `terrarium_size` | Vector3 | `Vector3(0.5, 0.4, 0.5)` |
| `num_walkers` | int (1-20) | `5` |
| `step_size` | float (0.001-0.1) | `0.015` |
| `steps_per_second` | float (1-120) | `30.0` |
| `trail_length` | int (10-1000) | `200` |
| `walk_mode` | WalkMode enum | `WALK_3D` |
| `walker_colors` | Array[Color] | 5 preset colors |

## Features

- Glass box enclosure with transparent walls and solid base
- MultiMesh walker rendering for efficient single-draw-call display
- Fading trail lines via ImmediateMesh with per-vertex alpha
- Three walk modes: 2D uniform, 3D uniform, and Levy flight
- Boundary reflection to keep walkers inside the terrarium
- Real-time MSD statistics display
- VR push-button panel for mode switching and reset
- Keyboard shortcuts (1/2/3 for modes, R for reset)

## Files

- `random_walk_terrarium.gd` -- Main script
- `random_walk_terrarium.tscn` -- Scene file
