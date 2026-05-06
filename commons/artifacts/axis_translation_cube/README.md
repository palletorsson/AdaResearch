# Axis Translation Cube

Demonstrates translation along a single axis (X, Y, or Z) by animating a wireframe cube back and forth with a start-move-wait-reverse cycle. Teaches how position changes along one axis while all other properties remain constant.

## How It Works

A cube rendered with the Grid wireframe shader oscillates along the chosen axis between positive and negative travel limits. The animation follows a four-state cycle: moving positive, waiting, moving negative, waiting. Trail ghost cubes rendered via MultiMesh show previous positions, creating a motion afterimage. A rail with colored endpoint markers (green for positive, red for negative) provides spatial reference. Labels display the current axis offset value and movement direction in real time.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `axis` | Axis enum | `Axis.Y` |
| `cube_size` | float | `0.15` |
| `travel_distance` | float | `0.4` |
| `travel_speed` | float | `0.3` |
| `wait_time` | float | `1.0` |
| `cube_color` | Color | `Color(0.3, 0.6, 1.0)` |
| `show_rail` | bool | `true` |
| `show_trail` | bool | `true` |
| `trail_count` | int | `4` |

## Features

- Configurable axis (X, Y, or Z) with per-axis color and direction labels
- Grid wireframe shader with emission glow that brightens during movement
- MultiMesh trail ghosts showing position history
- VR speed slider for real-time velocity control
- Rail with green/red endpoint markers
- Color feedback: cube brightens when moving, dims when waiting
- Separate scene variants for X, Y, and Z axes

## Files

- `axis_translation_cube.gd` -- Main script
- `axis_translation_cube.tscn` -- Generic scene file
- `x_translation_cube.tscn` -- X-axis variant
- `y_translation_cube.tscn` -- Y-axis variant
- `z_translation_cube.tscn` -- Z-axis variant
